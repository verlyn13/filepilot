#!/bin/bash
# Documentation Validation and Cross-Reference Checker
# Part of the agentic development cycle

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}📚 Documentation Validation System${NC}"
echo "=================================="

# Check if running in CI or local
if [ -n "$CI" ]; then
    echo "Running in CI environment"
else
    echo "Running in local development"
fi

# Function to validate JSON against schema
validate_json() {
    local file=$1
    local schema=$2

    if command -v ajv &> /dev/null; then
        echo -e "${BLUE}Validating $file against $schema${NC}"
        ajv validate -s "$schema" -d "$file" || return 1
    else
        echo -e "${YELLOW}ajv not installed, skipping JSON schema validation${NC}"
        echo "Install with: npm install -g ajv-cli"
    fi
    return 0
}

# Function to check markdown structure
check_markdown() {
    local file=$1

    echo -e "${BLUE}Checking markdown structure: $file${NC}"

    # Check for required headers
    if ! grep -q "^# " "$file"; then
        echo -e "${RED}  ✗ Missing top-level header${NC}"
        return 1
    fi

    # Check for version info
    if ! grep -qi "version:" "$file"; then
        echo -e "${YELLOW}  ⚠ Missing version information${NC}"
    fi

    # Check for last updated date
    if ! grep -qi "last.updated\|updated:" "$file"; then
        echo -e "${YELLOW}  ⚠ Missing last updated date${NC}"
    fi

    # Check max heading depth
    if grep -q "^#####" "$file"; then
        echo -e "${RED}  ✗ Heading depth exceeds maximum (4)${NC}"
        return 1
    fi

    echo -e "${GREEN}  ✓ Markdown structure valid${NC}"
    return 0
}

# Function to verify cross-references
check_cross_references() {
    local index_file="docs/CROSS_REFERENCE_INDEX.json"

    echo -e "${BLUE}Checking cross-references${NC}"

    if [ ! -f "$index_file" ]; then
        echo -e "${RED}  ✗ Cross-reference index not found${NC}"
        return 1
    fi

    # Check for broken links in cross-references
    local broken_count=0
    while IFS= read -r ref; do
        # Extract file path from reference
        file_path=$(echo "$ref" | sed 's/.*"\(.*\)".*/\1/')
        if [ -n "$file_path" ] && [ "$file_path" != "{" ] && [ "$file_path" != "}" ]; then
            if [ ! -f "$file_path" ] && [ ! -f "./$file_path" ]; then
                echo -e "${RED}  ✗ Broken reference: $file_path${NC}"
                ((broken_count++))
            fi
        fi
    done < <(grep -o '"[^"]*\.md"' "$index_file" | sort -u)

    if [ $broken_count -eq 0 ]; then
        echo -e "${GREEN}  ✓ All cross-references valid${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Found $broken_count broken references${NC}"
        return 1
    fi
}

# Function to check documentation completeness
check_completeness() {
    echo -e "${BLUE}Checking documentation completeness${NC}"

    local required_docs=(
        "DOCUMENTATION_INDEX.md"
        "plan.md"
        "INTEGRATED_PLAN.md"
        "agentic-workflow/README.md"
        "agentic-workflow/docs/API.md"
        "agentic-workflow/docs/DEVELOPMENT_PRINCIPLES.md"
        "agentic-workflow/docs/QUICKSTART.md"
    )

    local missing_count=0
    for doc in "${required_docs[@]}"; do
        if [ ! -f "$doc" ]; then
            echo -e "${RED}  ✗ Missing required document: $doc${NC}"
            ((missing_count++))
        else
            echo -e "${GREEN}  ✓ Found: $doc${NC}"
        fi
    done

    if [ $missing_count -eq 0 ]; then
        echo -e "${GREEN}  ✓ All required documents present${NC}"
        return 0
    else
        return 1
    fi
}

# Function to update cross-reference index
update_cross_references() {
    echo -e "${BLUE}Updating cross-reference index${NC}"

    # This would typically call a Node.js script to update the JSON
    # For now, we'll just update the timestamp
    if [ -f "docs/CROSS_REFERENCE_INDEX.json" ]; then
        current_date=$(date -u +"%Y-%m-%d")
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/\"lastUpdated\": \"[^\"]*\"/\"lastUpdated\": \"$current_date\"/" docs/CROSS_REFERENCE_INDEX.json
        else
            # Linux
            sed -i "s/\"lastUpdated\": \"[^\"]*\"/\"lastUpdated\": \"$current_date\"/" docs/CROSS_REFERENCE_INDEX.json
        fi
        echo -e "${GREEN}  ✓ Updated timestamp${NC}"
    fi
}

# Main validation flow
main() {
    local errors=0

    echo ""
    echo "1. Checking documentation completeness..."
    check_completeness || ((errors++))

    echo ""
    echo "2. Validating markdown structure..."
    for md_file in $(find . -name "*.md" \
        -not -path "*/node_modules/*" \
        -not -path "*/.bun/*" \
        -not -path "*/~/*" \
        -not -path "*/dist/*" \
        -not -path "*/build/*" \
        -not -path "*/coverage/*"); do
        check_markdown "$md_file" || ((errors++))
    done

    echo ""
    echo "3. Validating cross-references..."
    check_cross_references || ((errors++))

    echo ""
    echo "4. Validating JSON schemas..."
    if [ -f "docs/CROSS_REFERENCE_INDEX.json" ] && [ -f "docs/schemas/cross-reference.schema.json" ]; then
        validate_json "docs/CROSS_REFERENCE_INDEX.json" "docs/schemas/cross-reference.schema.json" || ((errors++))
    fi

    echo ""
    echo "5. Checking agent configuration..."
    if [ -f ".claude/config.yaml" ]; then
        echo -e "${GREEN}  ✓ Agent configuration found${NC}"
    else
        echo -e "${RED}  ✗ Agent configuration missing${NC}"
        ((errors++))
    fi

    # Update cross-references if no errors
    if [ $errors -eq 0 ]; then
        echo ""
        echo "6. Updating cross-references..."
        update_cross_references
    fi

    # Final report
    echo ""
    echo "=================================="
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ Documentation validation passed!${NC}"
        echo "All documents are valid, cross-referenced, and spec-compliant."
        exit 0
    else
        echo -e "${RED}❌ Documentation validation failed with $errors error(s)${NC}"
        echo "Please fix the issues above before committing."
        exit 1
    fi
}

# Run main function
main "$@"