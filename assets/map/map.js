    // Initialize map
    var map = L.map('map', {
      zoomControl: true,
      attributionControl: false,
      minZoom: MAP_CONFIG.minZoom,
      maxZoom: MAP_CONFIG.maxZoom
    }).setView([MAP_CONFIG.lat, MAP_CONFIG.lng], MAP_CONFIG.zoom);

    // Add OpenStreetMap tile layer
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: MAP_CONFIG.maxZoom,
      minZoom: MAP_CONFIG.minZoom
    }).addTo(map);

    // Storage for markers and polylines
    var markers = {};
    var polylines = {};

    // Notify Flutter when map is ready
    setTimeout(function() {
      FlutterChannel.postMessage(JSON.stringify({
        type: 'mapReady'
      }));
    }, 100);

    // Map click event
    map.on('click', function(e) {
      FlutterChannel.postMessage(JSON.stringify({
        type: 'mapClick',
        lat: e.latlng.lat,
        lng: e.latlng.lng
      }));
    });

    // Map long press event (contextmenu)
    map.on('contextmenu', function(e) {
      FlutterChannel.postMessage(JSON.stringify({
        type: 'mapLongPress',
        lat: e.latlng.lat,
        lng: e.latlng.lng
      }));
    });

    // Clear all markers
    function clearMarkers() {
      Object.values(markers).forEach(marker => {
        map.removeLayer(marker);
      });
      markers = {};
    }

  // Add marker
  function addMarker(lat, lng, color, type, id, userId) {
  try {
    var marker;

    if (type === 'current') {
      // Current location marker - pulsing dot
      var currentIcon = L.divIcon({
        className: 'custom-current-marker',
        html: '<div style="position: relative;">' +
              '<div style="width: 16px; height: 16px; background: ' + color + '; ' +
              'border-radius: 50%; ' +
              'box-shadow: 0 2px 6px rgba(0,0,0,0.3);"></div></div>',
        iconSize: [16, 16],
        iconAnchor: [8, 8]
      });
      marker = L.marker([lat, lng], { icon: currentIcon });
    } else if (type === 'user') {
      // User location marker - location pin with user ID
      var displayUserId = userId || 'User';
      var userIcon = L.divIcon({
        className: 'custom-user-marker',
        html: '<div style="position: relative; text-align: center;">' +
              '<svg width="28" height="36" viewBox="0 0 28 36" style="filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));">' +
              '<path d="M14 0 C6.3 0 0 6.3 0 14 C0 19.6 4.9 28 14 36 C23.1 28 28 19.6 28 14 C28 6.3 21.7 0 14 0 Z" ' +
              'fill="' + color + '"/>' +
              '<circle cx="14" cy="14" r="5" fill="white"/>' +
              '</svg>' +
              '<div style="position: absolute; top: 34px; left: 50%; transform: translateX(-50%); ' +
              'background: white; color: ' + color + '; padding: 1px 6px; border-radius: 8px; ' +
              'font-size: 10px; font-weight: bold; white-space: nowrap; ' +
              'box-shadow: 0 1px 3px rgba(0,0,0,0.2); border: 1px solid ' + color + ';">' +
              displayUserId + '</div></div>',
        iconSize: [28, 36],
        iconAnchor: [14, 36],
        popupAnchor: [0, -36]
      });
      marker = L.marker([lat, lng], { icon: userIcon });
    } else {
      // Default marker
      var defaultIcon = L.divIcon({
        className: 'custom-default-marker',
        html: '<div style="width: 20px; height: 20px; background: ' + color + '; ' +
              'border-radius: 50%; ' +
              'box-shadow: 0 2px 6px rgba(0,0,0,0.3);"></div>',
        iconSize: [20, 20],
        iconAnchor: [10, 10]
      });
      marker = L.marker([lat, lng], { icon: defaultIcon });
    }

    marker.addTo(map);
    markers[id] = marker;

    // Add click event
    marker.on('click', function(e) {
      console.log('Marker clicked:', id);
      FlutterChannel.postMessage(JSON.stringify({
        type: 'markerClick',
        markerId: id,
        lat: lat,
        lng: lng
      }));
      L.DomEvent.stopPropagation(e);
    });

  } catch (error) {
    console.error('Error adding marker:', error);
  }
}

    // Clear all polylines
    function clearPolylines() {
      Object.values(polylines).forEach(polyline => {
        map.removeLayer(polyline);
      });
      polylines = {};
    }

    // Add polyline
    function addPolyline(points, color, weight, id) {
      try {
        var polyline = L.polyline(points, {
          color: color,
          weight: weight,
          opacity: 0.7,
          lineJoin: 'round',
          lineCap: 'round'
        }).addTo(map);

        polylines[id] = polyline;
      } catch (error) {
        console.error('Error adding polyline:', error);
      }
    }

    // Move map to location
    function moveMap(lat, lng, zoom, offsetY = 0) {
  try {
    if (offsetY !== 0) {
      // Calculate offset position (move marker down = move map view up)
      const point = map.latLngToContainerPoint([lat, lng]);
      point.y -= offsetY; // Negative offset moves view up
      const newLatLng = map.containerPointToLatLng(point);

      map.setView(newLatLng, zoom, {
        animate: true,
        duration: 0.5
      });
    } else {
      // Normal centered view
      map.setView([lat, lng], zoom, {
        animate: true,
        duration: 0.5
      });
    }
  } catch (error) {
    console.error('Error moving map:', error);
  }
}


    // Fit bounds to show all markers and polylines
    function fitBounds() {
      try {
        var allLayers = Object.values(markers).concat(Object.values(polylines));

        if (allLayers.length > 0) {
          var group = L.featureGroup(allLayers);
          map.fitBounds(group.getBounds().pad(0.1), {
            animate: true,
            duration: 0.5
          });
        }
      } catch (error) {
        console.error('Error fitting bounds:', error);
      }
    }

    // Fit bounds with custom padding
    function fitBoundsWithPadding(padding) {
      try {
        var allLayers = Object.values(markers).concat(Object.values(polylines));

        if (allLayers.length > 0) {
          var group = L.featureGroup(allLayers);
          map.fitBounds(group.getBounds(), {
            padding: [padding, padding],
            animate: true,
            duration: 0.5
          });
        }
      } catch (error) {
        console.error('Error fitting bounds with padding:', error);
      }
    }

    // Get current map center
    function getCenter() {
      var center = map.getCenter();
      FlutterChannel.postMessage(JSON.stringify({
        type: 'centerResponse',
        lat: center.lat,
        lng: center.lng
      }));
    }

    // Get current map zoom
    function getZoom() {
      var zoom = map.getZoom();
      FlutterChannel.postMessage(JSON.stringify({
        type: 'zoomResponse',
        zoom: zoom
      }));
    }

    // Set map zoom
    function setZoom(zoom) {
      try {
        map.setZoom(zoom, {
          animate: true
        });
      } catch (error) {
        console.error('Error setting zoom:', error);
      }
    }

    console.log('Map script initialized');
