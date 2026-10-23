#!/usr/bin/env python3

import argparse
import sys


def reindent_scheme(code: str) -> str:
    # Forms that force a rigid +2 body indent.
    # Note: 'if', 'and', 'or', 'while' align bodies with the first argument
    # so they are intentionally omitted from this list.
    special_forms = {
        'define', 'define-syntax', 'define-values', 'define-macro',
        'let', 'let*', 'letrec', 'let-values', 'let*-values',
        'lambda', 'λ', 'cond', 'case', 'begin', 'do', 'delay',
        'when', 'unless', 'parameterize', 'match',
        'match-lambda', 'syntax-rules', 'syntax-case', 'with-syntax',
        'module', 'module+', 'provide', 'require', 'for', 'for*',
        'for/list', 'for/fold', 'for/and', 'for/or', 'struct', 'class',
        'local', 'fluid-let'
    }

    lines = code.splitlines()
    out_lines = []

    stack = []
    in_string = False
    in_block_comment = 0

    for line in lines:
        if in_string or in_block_comment > 0:
            out_lines.append(line)
            simulated_line = line
        else:
            stripped = line.lstrip()
            if not stripped:
                out_lines.append("")
                continue

            if stack:
                # Normal forms, special forms, and closing parentheses all
                # align with the expected body indent of the active open scope.
                current_indent = stack[-1][1]
            else:
                current_indent = 0

            simulated_line = (' ' * current_indent) + stripped
            out_lines.append(simulated_line)

        i = 0
        n = len(simulated_line)
        while i < n:
            c = simulated_line[i]

            if in_string:
                if c == '\\' and i + 1 < n:
                    i += 2
                elif c == '"':
                    in_string = False
                    i += 1
                else:
                    i += 1
                continue

            if in_block_comment > 0:
                if c == '|' and i + 1 < n and simulated_line[i+1] == '#':
                    in_block_comment -= 1
                    i += 2
                elif c == '#' and i + 1 < n and simulated_line[i+1] == '|':
                    in_block_comment += 1
                    i += 2
                else:
                    i += 1
                continue

            if c == '#' and i + 1 < n and simulated_line[i+1] == '|':
                in_block_comment += 1
                i += 2
                continue

            if c == ';':
                break

            elif c == '"':
                in_string = True
                i += 1
                continue

            elif c in '([{':
                paren_col = i
                i += 1

                while i < n and simulated_line[i].isspace():
                    i += 1

                if i == n or simulated_line[i] in '()[]{};"':
                    # Standard inner lists align by 1 space relative to the parenthesis
                    stack.append((paren_col, paren_col + 1))
                    continue

                start_word = i
                while i < n and not simulated_line[i].isspace() and simulated_line[i] not in '()[]{};"':
                    i += 1
                word = simulated_line[start_word:i]

                if word in special_forms:
                    stack.append((paren_col, paren_col + 2))
                else:
                    while i < n and simulated_line[i].isspace():
                        i += 1
                    if i < n and simulated_line[i] != ';':
                        # Standard functions align strictly with their first argument (bracket height matching)
                        stack.append((paren_col, i))
                    else:
                        stack.append((paren_col, paren_col + 1))
                continue

            elif c in ')]}':
                if stack:
                    stack.pop()
                i += 1
            else:
                i += 1

    return '\n'.join(out_lines)


def process_file(input_filename: str, output_filename: str = None):
    try:
        with open(input_filename, 'r', encoding='utf-8') as f:
            raw_code = f.read()

        formatted_code = reindent_scheme(raw_code)
        target_file = output_filename if output_filename else input_filename

        with open(target_file, 'w', encoding='utf-8') as f:
            f.write(formatted_code + '\n')

        print(f"Reindented: {target_file}")

    except FileNotFoundError:
        print(f"Error: Could not find '{input_filename}'", file=sys.stderr)
        sys.exit(1)
    except IOError as e:
        print(f"File error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="DrRacket-style Scheme code reindenter")
    parser.add_argument("input", help="Path to the input .scm / .rkt file")
    parser.add_argument("-o", "--output", help="Optional output file path.")

    args = parser.parse_args()
    process_file(args.input, args.output)
