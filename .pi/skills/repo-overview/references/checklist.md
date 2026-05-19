[ ] repository explored
[ ] content for overview.html gathered and organized
    - a list of the tech stack involved: languages, frameworks, libraries, and tools used in the codebase which are used in the central parts of the project, e.g., QT6 for GUI, cmake for build, catch2 or pytest for testing, jax or torch for machine learning, etc.
    - A note about the dominant coding and testing paradigms used in the codebase
    - a class diagram. This should include functions and other code entities part of the data flow too.
    - a short description of each class
    - a module diagram
    - a description of each module
    - tests and fixtures and to which parts of the codebase they relate
    - how to run tests, or the main entry point if the codebase is a runable application
    - any constraints, risks, or open questions about the codebase that would be relevant for a new contributor or someone trying to understand how to make changes in this area.
    - add in a pointer to the documentation if it exists
[ ] overview.html written
[ ] overview.html rendering checked and corrected if needed
[ ] Content of overview.html checks completed:
 - tech stack listed with relevant tools, languages, and frameworks
 - coding and testing paradigms noted
 - checked that invokation instructions for tests and entry points are correct and follow the syntax of the appropriate shell of the user's environment and are adjusted to the user's platform
 - content headings and ids exist
 - there are no leftover 'example' or other placeholder content from the  references/example.html file in overview.html
 - the required sections are present in the file and in a logical order
 - the diagrams render correctly without syntax errors
 - no domain specific terms are copied over from the references/example.html file
 - only relative paths are used for any file references in the output file
 - no person names or pronouns are used in the content, it should be factual and impersonal
 - no paths are leaked from the agent's environment, only paths relevant to the target repository and relative to the repository root
[ ] final output path returned