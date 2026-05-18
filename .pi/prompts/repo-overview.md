Use the scout agent to understand the codebase in the repository at:

$@

Render your output into a single html file with the diagrams and the above information organized in succinct and clear way. Write this file into scout/overview.html in the repository.
Secondly, produce a .md file with the same content, but in a more concise format for reading by other AI agents in the workflow. Write this file into scout/overview.md in the repository.
Do not write any other files or output. Do not write all your findings into the conversation, return only the path to the final output file.

Come back with:
- a class diagram
- a short description of each class
- a module diagram
- a description of each module
- tests and fixtures and to which parts of the codebase they relate
- how to run tests, or the main entry point if the codebase is a runable application
- any constraints, risks, or open questions about the codebase that would be relevant for a new contributor or someone trying to understand how to make changes in this area.
- add in a pointer to the documentation if it exists

after writing the html file, go and check again if it is correct and if it contains all the required information. Correct all syntax errors you find before returning the path to the output file.