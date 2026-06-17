/**
 * Fetch OpenAPI schema from server
 * @returns {Promise<Object>}
 */
export async function getOpenAPISchema() {
  const response = await fetch('/docs/openapi.json');
  if (!response.ok) {
    throw new Error('Failed to fetch OpenAPI schema');
  }
  return await response.json();
}

/**
 * Resolve a $ref reference to the actual schema
 * @param {Object} schema - Schema object that may contain $ref
 * @param {Object} components - OpenAPI components object
 * @returns {Object} - Resolved schema object
 */
function resolveSchema(schema, components) {
  if (!schema) return schema;

  // If it's a $ref, resolve it
  if (schema.$ref) {
    const refPath = schema.$ref.replace('#/components/schemas/', '');
    schema = components?.schemas?.[refPath] || schema;
  }

  // Recursively resolve properties
  if (schema.properties) {
    const resolvedProperties = {};
    for (const [key, value] of Object.entries(schema.properties)) {
      resolvedProperties[key] = resolveSchema(value, components);
    }
    schema = { ...schema, properties: resolvedProperties };
  }

  // Resolve items schema for arrays
  if (schema.items) {
    schema = { ...schema, items: resolveSchema(schema.items, components) };
  }

  return schema;
}

/**
 * Extract part definitions from OpenAPI schema
 * @param {Object} openapi - OpenAPI schema object
 * @returns {Object} - Map of part_id to part definition
 */
export function extractParts(openapi) {
  const parts = {};
  const components = openapi.components || {};

  if (!openapi.paths) {
    return parts;
  }

  for (const [path, methods] of Object.entries(openapi.paths)) {
    if (!methods.post) continue;

    const post = methods.post;

    // Get request body schema (handle both application/json and */*)
    const content = post.requestBody?.content || {};
    let requestBody = content['application/json']?.schema || content['*/*']?.schema;
    if (!requestBody) continue;

    // Check if endpoint returns STL (check 200 or default response with any content type)
    const responses = post.responses || {};
    const stlResponse = responses[200]?.content?.['model/stl'] || responses[200]?.content?.['*/*'] || responses['default']?.content?.['model/stl'] || responses['default']?.content?.['*/*'];
    if (!stlResponse) continue;

    // Resolve $ref to actual schema
    requestBody = resolveSchema(requestBody, components);

    const partId = path.replace('/api/', '');

    parts[partId] = {
      id: partId,
      name: post.summary || partId.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()),
      description: post.description || '',
      endpoint: path,
      schema: requestBody,
    };
  }

  return parts;
}

/**
 * Generate blob from endpoint
 * @param {string} endpoint - API endpoint
 * @param {Object} parameters - Parameters object
 * @returns {Promise<{blob: Blob, filename: string}>}
 */
export async function generateBlob(endpoint, parameters) {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(parameters),
  });

  if (!response.ok) {
    const error = await response.text().catch(() => 'Model generation failed');
    throw new Error(error || 'Model generation failed');
  }

  const contentDisposition = response.headers.get('Content-Disposition');
  let filename = null;

  const filenameMatch = contentDisposition?.match(/filename="?([^"]+)"?/);
  if (filenameMatch) {
    filename = filenameMatch[1].trim();
  }

  return {
    blob: await response.blob(),
    filename,
  };
}

/**
 * Download arbitrary blob as file
 * @param {Blob} blob - Blob to download
 * @param {string} filename - Filename for download
 */
export function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');

  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();

  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

/**
 * Generate STL from endpoint
 * @param {string} endpoint - API endpoint
 * @param {Object} parameters - Parameters object
 * @returns {Promise<{blob: Blob, filename: string}>}
 */
export async function generateSTL(endpoint, parameters) {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(parameters),
  });

  if (!response.ok) {
    const error = await response.text().catch(() => 'Model generation failed');
    throw new Error(error || 'Model generation failed');
  }

  // Extract filename from Content-Disposition header
  const contentDisposition = response.headers.get('Content-Disposition');
  let filename = null;
  if (contentDisposition) {
    filename = contentDisposition.split('filename=')[1].replace(/"/g, '').trim();
  }

  const blob = await response.blob();
  return { blob, filename };
}

/**
 * Download STL blob as file
 * @param {Blob} blob - STL blob
 * @param {string} filename - Filename for download
 */
export function downloadSTL(blob, filename) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

/**
 * Get default values from schema
 * @param {Object} schema - JSON schema
 * @returns {Object} - Default values object
 */
export function getDefaultValues(schema) {
  const defaults = {};

  if (!schema?.properties) {
    return defaults;
  }

  for (const [name, props] of Object.entries(schema.properties)) {
    if (props.default !== undefined) {
      defaults[name] = props.default;
    } else if (props.type === 'boolean') {
      defaults[name] = false;
    } else if (props.type === 'number' || props.type === 'integer') {
      defaults[name] = 0;
    } else if (props.type === 'string' && props.enum) {
      // String enum - use first value as default
      defaults[name] = props.enum[0];
    } else if (props.type === 'string') {
      defaults[name] = '';
    } else if (props.type === 'array') {
      defaults[name] = [];
    } else if (props.type === 'object') {
      defaults[name] = {};
    } else {
      defaults[name] = null;
    }
  }

  return defaults;
}

/**
 * Generate filename from part info and parameters
 * @param {Object} part - Part definition
 * @param {Object} parameters - Current parameters
 * @returns {string} - Generated filename
 */
export function generateFilename(part, parameters) {
  const segments = [part.id];

  // Add key dimension parameters to filename
  const dimensionFields = ['columns', 'rows', 'width', 'depth', 'height', 'length', 'slots', 'hooks'];
  for (const field of dimensionFields) {
    if (parameters[field] !== undefined) {
      segments.push(String(parameters[field]));
    }
  }

  // Add variant if present
  if (parameters.variant !== undefined) {
    const variantSlug = String(parameters.variant).toLowerCase().replace(/ /g, '_');
    segments.push(variantSlug);
  }

  return `${segments.join('-')}.stl`;
}
