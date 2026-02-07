---
name: Performance Guidelines
description: Rules for optimizing performance across codebases.
globs: ["**/*.py", "**/*.java", "**/*.js", "**/*.jsx", "**/*.ts", "**/*.tsx"]
---

# Performance Optimization Rules
- Identify O(n²) or worse patterns and recommend more efficient alternatives.
- Avoid unnecessary loops, recursion, or large intermediate structures.
- Reuse existing objects or data where possible.
- Prefer lazy evaluation or generators in Python when working with large datasets.
- Cache results for expensive computations when appropriate.
- In Java, use streams efficiently but avoid overusing parallel streams.
- Minimize I/O and network calls inside loops.
- Always verify that performance changes do not reduce code readability or correctness.
