/**
 * Parse Pydantic validation errors from error message
 * @param {string} message - Error message from backend
 * @returns {Object} - Map of field name to error message
 */
export function parseValidationErrors(message) {
    const fieldErrors = {};

    if (!message) return fieldErrors;

    // Split message into sections by "N validation errors? for ModelName" lines
    // This helps us identify nested model errors
    const sections = message.split(/(\d+ validation errors? for \w+)/);

    // Track which fields are array fields that contain nested models
    const arrayFieldMap = {
        'MountHole': 'holes',
        'CableclipDefinition': 'clips',
    };

    // Process sections to find nested errors
    for (let i = 0; i < sections.length; i++) {
        const section = sections[i];
        const nestedMatch = section.match(/\d+ validation errors? for (\w+)/);

        if (nestedMatch) {
            const modelName = nestedMatch[1];
            const arrayField = arrayFieldMap[modelName];

            // The next section contains the actual errors
            if (arrayField && i + 1 < sections.length) {
                const errorBlock = sections[i + 1];
                const lines = errorBlock.split('\n');
                const nestedErrors = parseErrorLines(lines);
                const errorMessages = Object.values(nestedErrors);

                if (errorMessages.length > 0) {
                    // Show a summary of all errors for this array field
                    fieldErrors[arrayField] = `Invalid values: ${errorMessages.join('; ')}`;
                }
                i++; // Skip the error block we just processed
            }
        }
    }

    // Also parse top-level errors (lines before any nested "N validation errors" sections)
    const topLevelMatch = message.match(/(?:Error: \d+ validation errors? for \w+\n)([\s\S]+)$/);
    if (topLevelMatch) {
        let errorBlock = topLevelMatch[1];
        // Find where nested errors start
        const nestedStart = errorBlock.search(/\n\d+ validation errors? for /);
        if (nestedStart > 0) {
            // Only parse lines before the nested section
            errorBlock = errorBlock.substring(0, nestedStart);
        }
        const lines = errorBlock.split('\n');
        const topLevelErrors = parseErrorLines(lines);
        // Add top-level errors (don't overwrite nested errors we already parsed)
        for (const [key, value] of Object.entries(topLevelErrors)) {
            if (!(key in fieldErrors)) {
                fieldErrors[key] = value;
            }
        }
    }

    return fieldErrors;
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
        // Field names can be: gridz_define, holes.0.x_offset, etc.
        if (!line.startsWith(' ') && !line.startsWith('\t') && /^[a-z_][a-z0-9_.]*$/.test(trimmed)) {
            currentField = trimmed;
        } else if (currentField && (trimmed.startsWith('Input should be') || trimmed.startsWith('Value error'))) {
            // Extract the meaningful part of the error message
            let errorMsg;
            const inputMatch = trimmed.match(/^Input should be (.+?) \[type=/);
            const valueMatch = trimmed.match(/^Value error, (.+?) \[type=/);

            if (inputMatch) {
                errorMsg = `Expected: ${inputMatch[1]}`;
            } else if (valueMatch) {
                errorMsg = valueMatch[1];
            } else {
                errorMsg = 'Invalid value';
            }

            // Handle dotted paths like "holes.0.x_offset"
            const parts = currentField.split('.');

            if (parts.length > 1) {
                // Nested field like "holes.0.diameter" -> store with full path
                const key = parts.join('.');
                fieldErrors[key] = errorMsg;
                // Also store under top-level field for generic display
                const topLevelField = parts[0];
                if (!fieldErrors[topLevelField]) {
                    fieldErrors[topLevelField] = errorMsg;
                }
            } else {
                fieldErrors[currentField] = errorMsg;
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
