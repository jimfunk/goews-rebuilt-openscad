/**
 * Parse Pydantic validation errors from error message
 * @param {string} message - Error message from backend
 * @returns {Object} - Map of field name to error message
 */
export function parseValidationErrors(message) {
  const fieldErrors = {};

  if (!message) return fieldErrors;

  // Pydantic error format:
  // "Invalid request body: ModelName. Error: N validation errors for ModelName\nfield_name\n  Input should be..."
  // or simpler format: "field_name\n  Input should be..."

  // Try to find the validation errors section
  const validationMatch = message.match(/(?:Error: \d+ validation errors for \w+\n)([\s\S]+)$/);
  if (!validationMatch) {
    // Try simpler format - just field errors after the first line
    const lines = message.split('\n');
    if (lines.length > 1) {
      return parseErrorLines(lines.slice(1));
    }
    return fieldErrors;
  }

  const errorBlock = validationMatch[1];
  const lines = errorBlock.split('\n');
  return parseErrorLines(lines);
}

/**
 * Parse error lines into field error map
 * @param {string[]} lines - Lines of error text
 * @returns {Object} - Map of field name to error message
 */
function parseErrorLines(lines) {
  const fieldErrors = {};
  let currentField = null;

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed) continue;

    // Check if this is a field name (no indentation, no special chars at start)
    // Field names are like: gridz_define, style_tab, etc.
    if (!line.startsWith(' ') && !line.startsWith('\t') && /^[a-z_][a-z0-9_]*$/.test(trimmed)) {
      currentField = trimmed;
    } else if (currentField && trimmed.startsWith('Input should be')) {
      // Extract the meaningful part of the error message
      // "Input should be 'Gridz Units (7mm excl lip)', ..." -> "Invalid value"
      // We'll simplify to a user-friendly message
      const match = trimmed.match(/^Input should be (.+?) \[type=/);
      if (match) {
        fieldErrors[currentField] = `Expected: ${match[1]}`;
      } else {
        fieldErrors[currentField] = 'Invalid value';
      }
    } else if (currentField && trimmed.startsWith('[type=')) {
      // Skip type metadata lines
    } else if (currentField && trimmed.startsWith('For further information')) {
      // Skip Pydantic info links
    } else if (currentField && !fieldErrors[currentField]) {
      // Some other error message for this field
      fieldErrors[currentField] = trimmed;
    }
  }

  return fieldErrors;
}

/**
 * Check if an error is a validation error (has field-level errors)
 * @param {string} message - Error message
 * @returns {boolean}
 */
export function isValidationError(message) {
  if (!message) return false;
  return message.includes('validation error') || message.includes('Input should be');
}
