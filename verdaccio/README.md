# Verdaccio

Verdaccio is a lightweight private npm proxy registry built in Node.js

## Setting up global registry for all projects
To set the registry for all your local projects in any terminal window run:

npm set registry http://localhost:4873/

This will set the registry for your operational system user and you can find it on the file ~/.npmrc.

## Using registry for a specific project
To set this value for a specific project open its root folder on a terminal window and run:

npm set registry http://localhost:4873/ --location project

This will set the registry in a .npmrc file in your project root directory.