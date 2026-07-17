# Development Agreement

This document defines the coding and Git workflow agreements for the project.

## Code

1. Use English throughout the codebase.
2. Export assets from Sketch.
3. Use `camelCase` for variable and asset names.
4. Use `PascalCase` for file and function names.
5. Document each function or section of code you work on. The documentation should help others understand what the code does and where it is referenced.

   Example:

   ```swift
   // This function adds a new button.
   ```

6. Follow separation of concerns and use the MVVM architecture.
7. Use AI responsibly. You must be able to explain the code you submit. Ensure that the code is clean, follows best practices, and is reusable.
8. Work within your own folder or file. Do not modify or mix your work with someone else's without discussing it with them first.

## Git

1. Follow the project's commit-message convention, such as `Fix:` or `Refactor:`. Keep commit messages simple and clear.

   Example:

   ```text
   Fix: Add new task feature
   ```

2. Name feature branches using `feature/camelCase`.
3. Follow this development flow:

   1. Pull the latest changes from the `test` branch to ensure that your branch is up to date.
   2. Work on your own branch.
   3. Pull the latest `test` branch into your branch. Resolve all conflicts before merging.
   4. Merge your branch into the `test` branch.
   5. Open a pull request to the `staging` branch. This triggers the Xcode Cloud workflow for TestFlight.

4. Use Xcode Cloud to automatically upload TestFlight builds from the `staging` branch.
5. Project setup PIC: Farrell.
6. The feature PIC is responsible for merging the feature into `staging`.
