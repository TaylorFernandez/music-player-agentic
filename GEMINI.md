# Description
This is the aim of the project. I want an mp3 player that is able to connect to a server and retrieve data about the song that is current playing. I NEVER want this project to store actual mp3 files. The main goal of the project is to use whatever metadata is available within the mp3 file to figure out which song is currently playing and send the mp3 player any additional data the server/database might have about it.

# Goals
1. The mp3 player must be able to playback mp3 files and provide ALL users all basic mp3 player functionality. 
2. Users will NEVER be forced to login. User's who choose to login via username/password or using Google SSO will be provided with the additional features that the server is able to provide.  
3. Users will be able to see all data about all of their media on a website served by the backend. This will be integrated into the server.
4. The website served by the backend MUST be implement role based access. here are the available roles
  1. General user: Users can view all data about any song stored in the database. These users will also be allowed to create or edit ANY data about ANY song. The catch here is that any modification MUST be reviewed my a moderator before the data is actually saved. 
  2. Moderator: These users have all the same permissions that general users have BUT will also be able to approve, edit, or deny any change requests general users make. In cases where this moderator makes a change to any data, it MUST be reviewed by another moderator or the owner of the application/server
  3. Owner: This use role will have all the same permissions as the moderator BUT owners will be able to make changes to ANY data stored in the database, with the option to avoid needing review. The review should be optional in case the owner want's a second opinion or a second pair of eyes. 
  
# Data Store in Database
The database should store the following data: 
1. Song title
2. Song Artist
3. Song album
4. Song Artwork
5. Song duration
6. Song lyrics
7. Album name
8. Album covers
9. Album Artist
10. Album Type (Ex: Album, EP, Single, etc.) 
11. Description of the album
12. Artist name
13. Artist image
14. Artist bio/description


# Database Structure
There are three main object types: Song, Album, Artist.
The database must follow the following rules for the structure:

1. There can be multiple songs in a single album
2. A song can belong to multiple albums. An example would be a song is released as a single and then added as part of an Album or EP
3. There can be many albums linked to an artist
4. There can be many artists linked to an album, ep, or single


# Technologies Used
The app will be written in Flutter
The server will be written in Django
The site served by Django will use django templates
The database for this project will be PostgreSQL

You're allowed to use any libraries within those tech stacks.

# Addition Notes and Consideration
1. Create any logo you see fit. make sure they match on the app and the website (favicon as well)
2. Don't forget the app MUST be able to be used without logging in. This should provide the basic functionality an mp3 player should have
3. Have fun! This is your project so design things as you see fit.
4. I've defined two folders in this projects ./UI Designs Templates/ folder. Within that folder are two subdirectories: Backend and Frontend. When designing the backend, use the backend folder. When designing the front end, use the frontend folder.
5. There is a Docs folder in the root of this project. When creating plans or writing documents, organize those files as you see fit in the Docs directory. This should include any plans, memories, progress, etc.
6. Before working on anything, make sure you read from your memories in the ./Docs/memory.md file
7. DO NOT write your thinking in actual code files. If you want to note down a thought, write it in a file ./Docs/thoughts.md
8. When a phase is completed. Test BOTH the front and back ends to make sure they compile
