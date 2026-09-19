# AGENTS.md — Development & Coding Guidelines

## 1. Core Philosophy
* **KISS & YAGNI First**: Implement only what is directly requested. Never anticipate hypothetical future requirements.
* **Reject Over-Engineering**: Prefer a single clean function over a hierarchy of interfaces, factories, and builders.
* **Standard Library Priority**: Maximize use of standard library features and modern language idioms before introducing custom helpers or external packages.

## 2. Code Generation & Style
* **Zero Defensive Bloat**: Do not introduce unnecessary `try-catch` wrappers, redundant null/nil/type assertions, or trivial data transformation layers unless required by boundary contracts.
* **High Information Density**: Write idiomatic, compact code. Avoid boilerplate getters/setters, repetitive log statements, and useless boilerplate types.
* **Meaningful Comments Only**: Do NOT comment on self-evident code, function names, or boilerplate. Reserve comments exclusively for non-obvious algorithms, race condition mitigations, or hardware/OS-level quirks.

## 3. Editing & Refactoring Constraints
* **Surgical Edits**: Touch only the functions or lines directly related to the task. Keep diffs as small as possible.
* **No Full-File Dumps**: When updating existing code, provide only the modified functions or targeted replacements. Never regenerate an entire unchanged file.
* **Dead Code Pruning**: If a refactor renders previous functions, variables, or imports obsolete, eliminate them immediately rather than commenting them out.

## 4. Communication Rules
* **No Conversational Fluff**: Skip pleasantries, restating the prompt, and generic concluding remarks.
* **Brief Context**: If an implementation detail requires explanation, keep it to 1–2 bullet points directly below the code block.
