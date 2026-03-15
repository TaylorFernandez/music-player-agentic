#!/usr/bin/env python3
"""
Script to fix Django template files by:
1. Removing markdown code block delimiters
2. Fixing line breaks in Django template tags
"""

import os
import re


def fix_template_file(filepath):
    """Fix a single template file."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    original_content = content

    # Remove markdown code block delimiters at the start
    if content.startswith("```") or content.startswith("music player app"):
        lines = content.split("\n")
        # Remove first line if it's a markdown delimiter
        if lines[0].startswith("```") or "music player app" in lines[0]:
            lines = lines[1:]
        # Remove last line if it's a closing backtick
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        content = "\n".join(lines)

    # Fix template tags split across lines
    # Pattern: {% if\n    not forloop.last %} -> {% if not forloop.last %}
    content = re.sub(
        r"\{%\s*if\s*\n\s*(not\s+forloop\.last)\s*\%}", r"{% if \1 %}", content
    )
    content = re.sub(r"\{%\s*if\s*\n\s*(forloop\.last)\s*\%}", r"{% if \1 %}", content)

    # Fix other common template tag breaks
    content = re.sub(
        r"\{%\s*url\s*\n\s*(\'[^\']+\'\s+pk=\w+\.id)\s*\%}", r"{% url \1 %}", content
    )

    # Ensure proper spacing in template tags
    content = re.sub(r"\{%\s+", "{% ", content)
    content = re.sub(r"\s*\%}", " %}", content)

    # Fix multiline template tags
    lines = content.split("\n")
    fixed_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Check if line contains an unclosed template tag
        if "{%" in line and "%}" not in line:
            # Merge with next line if it contains the closing tag
            if i + 1 < len(lines):
                next_line = lines[i + 1]
                merged = line + " " + next_line.strip()
                if "%}" in merged:
                    fixed_lines.append(merged)
                    i += 2
                    continue

        fixed_lines.append(line)
        i += 1

    content = "\n".join(fixed_lines)

    # Write back only if changes were made
    if content != original_content:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        return True

    return False


def main():
    """Main function to fix all template files."""
    # Find all HTML files in templates directory
    template_files = []
    for root, dirs, files in os.walk("backend/templates/web"):
        for file in files:
            if file.endswith(".html"):
                template_files.append(os.path.join(root, file))

    fixed_count = 0

    print("Fixing Django template files...")
    print(f"Working directory: {os.getcwd()}")
    print("=" * 50)

    # Fix each file
    for filepath in sorted(template_files):
        try:
            if fix_template_file(filepath):
                print(f"✓ Fixed: {filepath}")
                fixed_count += 1
            else:
                print(f"  OK: {filepath}")
        except Exception as e:
            print(f"✗ Error fixing {filepath}: {e}")

    print()
    print("=" * 50)
    print(f"Fixed {fixed_count} template files.")
    print("=" * 50)


if __name__ == "__main__":
    # Change to the project root directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    main()
