# Here We Go

Here We Go is a real-time location sharing solution built with **Node.js** and **Socket.IO**. It provides seamless **route visualization** between shared locations by integrating **OpenStreetMap** with the **OSRM API**.  

## Features
- Real-time location sharing between users  
- Interactive map using **OpenStreetMap**  
- Route visualization with **OSRM API** ([Routing API](http://router.project-osrm.org/route/v1/driving/))  
- Powered by **Node.js** backend with **Socket.IO** for real-time communication  

## Preview

![HereWeGo](assets/herewego.gif)

## Setup Guide

- Start the `herewego-server` by running `npm run dev`.
- Use ngrok to expose the local server to the internet by running `ngrok http 3000` (the backend runs on port 3000).
- Launch the application, connect it to the server, and enable location sharing with other users.
- Set up the following Node.js server to test real-time location sharing and route visualization.

``` javascript
const io = require('socket.io-client');

// Configuration
const SERVER_URL = '';
const ROOM_ID = '';


const users = [
  { userId: '', lat: , lng:  }
  { userId: '', lat: , lng:  },
  { userId: '', lat: , lng:  },
  { userId: '', lat: , lng:  },
  { userId: '', lat: , lng:  }
];

// Store socket connections
const connections = [];

// Connect a single user
function connectUser(user) {
  return new Promise((resolve, reject) => {
    console.log(`\nConnecting ${user.userId}...`);
    
    const socket = io(SERVER_URL, {
      transports: ['websocket'],
      reconnection: true
    });

    socket.on('connect', () => {
      console.log(`${user.userId} connected (Socket ID: ${socket.id})`);
      
      // Join room
      socket.emit('join-room', {
        roomId: ROOM_ID,
        userId: user.userId
      });
    });

    socket.on('joined-room', (data) => {
      console.log(`${user.userId} joined room: ${data.roomId}`);
      console.log(`   Users in room: ${data.usersInRoom.join(', ')}`);
      
      resolve({
        socket,
        userId: user.userId,
        currentLat: user.lat,
        currentLng: user.lng
      });
    });

    socket.on('user-joined', (data) => {
      console.log(`${user.userId} sees: ${data.userId} joined the room`);
    });

    socket.on('user-left', (data) => {
      console.log(`${user.userId} sees: ${data.userId} left the room`);
    });

    socket.on('location-update', (data) => {
      console.log(`${user.userId} received location from ${data.userId}: (${data.latitude.toFixed(4)}, ${data.longitude.toFixed(4)})`);
    });

    socket.on('existing-locations', (data) => {
      const userCount = Object.keys(data).length;
      console.log(`${user.userId} received ${userCount} existing location(s)`);
    });

    socket.on('location-shared', (data) => {
    });

    socket.on('error', (data) => {
      console.error(`${user.userId} error: ${data.message}`);
    });

    socket.on('disconnect', (reason) => {
      console.log(`${user.userId} disconnected: ${reason}`);
    });

    socket.on('connect_error', (error) => {
      console.error(`${user.userId} connection error:`, error.message);
      reject(error);
    });

    // Store user data with socket
    socket.userData = user;
  });
}

// Share location for a user
function shareLocation(connection) {
  const { socket, userId, currentLat, currentLng } = connection;
  
  socket.emit('share-location', {
    roomId: ROOM_ID,
    userId: userId,
    latitude: currentLat,
    longitude: currentLng
  });
  
  console.log(`${userId} shared location: (${currentLat.toFixed(4)}, ${currentLng.toFixed(4)})`);
}

// Simulate movement (random walk)
function simulateMovement(connection) {
  // Small random movement (roughly 0.001 degrees ≈ 100 meters)
  const deltaLat = (Math.random() - 0.5) * 0.002;
  const deltaLng = (Math.random() - 0.5) * 0.002;
  
  connection.currentLat += deltaLat;
  connection.currentLng += deltaLng;
  
  shareLocation(connection);
}

// Main simulation function
async function runSimulation() {
  console.log('Starting Location Sharing Simulation');
  console.log(`Server: ${SERVER_URL}`);
  console.log(`Room: ${ROOM_ID}`);
  console.log(`Users: ${users.length}`);
  console.log('='.repeat(60));

  try {
    // Connect all users
    console.log('\n PHASE 1: Connecting Users');
    console.log('-'.repeat(60));
    
    for (const user of users) {
      const connection = await connectUser(user);
      connections.push(connection);
      
      // Wait a bit between connections to see the flow
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    // Wait for all connections to stabilize
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Share initial locations
    console.log('\n PHASE 2: Sharing Initial Locations');
    console.log('-'.repeat(60));
    
    for (const connection of connections) {
      shareLocation(connection);
      await new Promise(resolve => setTimeout(resolve, 500));
    }

    // Simulate movement updates
    console.log('\n PHASE 3: Simulating Movement (5 minutes)');
    console.log('-'.repeat(60));
    
    const movementInterval = setInterval(() => {
      // Randomly select 1-2 users to move
      const numMoving = Math.floor(Math.random() * 2) + 1;
      const shuffled = [...connections].sort(() => Math.random() - 0.5);
      
      for (let i = 0; i < numMoving; i++) {
        simulateMovement(shuffled[i]);
      }
    }, 3000); // Update every 3 seconds

    // Run for 5 minutes (300 seconds)
    await new Promise(resolve => setTimeout(resolve, 300000));
    clearInterval(movementInterval);

    // Disconnect some users
    console.log('\n PHASE 4: Simulating User Departures (Alice & Bob leaving)');
    console.log('-'.repeat(60));
    
    const usersToDisconnect = connections.slice(0, 2);
    for (const connection of usersToDisconnect) {
      console.log(`Disconnecting ${connection.userId}...`);
      connection.socket.disconnect();
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    // Continue with remaining users for 3 minutes (180 seconds)
    console.log('\n Remaining users continue for 3 more minutes...');
    console.log('-'.repeat(60));
    await new Promise(resolve => setTimeout(resolve, 180000));

    // Clean up
    console.log('\n PHASE 5: Cleaning Up (Disconnecting remaining users)');
    console.log('-'.repeat(60));
    
    for (const connection of connections) {
      if (connection.socket.connected) {
        console.log(`Disconnecting ${connection.userId}...`);
        connection.socket.disconnect();
      }
    }

    console.log('\n Simulation Complete!');
    console.log('='.repeat(60));
    
    process.exit(0);
  } catch (error) {
    console.error('Simulation error:', error);
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\n Received SIGINT, cleaning up...');
  for (const connection of connections) {
    if (connection.socket.connected) {
      connection.socket.disconnect();
    }
  }
  process.exit(0);
});

// Run the simulation
runSimulation();
```

**Note:** Ensure the SERVER_URL matches the URL provided by ngrok http 3000, and use the same ROOM_ID in both the server and the app to establish a successful connection.