import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get_work_app/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class JobLocationMap extends StatefulWidget {
  final String locationText;
  final double? width;
  final double? height;

  const JobLocationMap({
    super.key,
    required this.locationText,
    this.width,
    this.height = 151,
  });

  @override
  State<JobLocationMap> createState() => _JobLocationMapState();
}

class _JobLocationMapState extends State<JobLocationMap> {
  GoogleMapController? _mapController;
  LocationData? _locationData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final locationData = await LocationService.getLocationData(widget.locationText);
      
      if (mounted) {
        setState(() {
          _locationData = locationData;
          _isLoading = false;
          _hasError = locationData == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _openInMaps() async {
    if (_locationData == null) return;

    try {
      // Try Google Maps first
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${_locationData!.latitude},${_locationData!.longitude}';
      final googleMapsUri = Uri.parse(googleMapsUrl);
      
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Apple Maps on iOS or generic maps
        final fallbackUrl = 'https://maps.apple.com/?q=${_locationData!.latitude},${_locationData!.longitude}';
        final fallbackUri = Uri.parse(fallbackUrl);
        
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildMapContent(),
      ),
    );
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError || _locationData == null) {
      return _buildErrorState();
    }

    return _buildMapView();
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7551FF)),
            ),
            SizedBox(height: 8),
            Text(
              'Loading map...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF524B6B),
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              widget.locationText.isNotEmpty ? widget.locationText : 'Location not available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'DM Sans',
              ),
            ),
            const SizedBox(height: 8),
            if (widget.locationText.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  final query = Uri.encodeComponent(widget.locationText);
                  final url = 'https://www.google.com/maps/search/?api=1&query=$query';
                  final uri = Uri.parse(url);
                  
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7551FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'View on Maps',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7551FF),
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final latLng = LatLng(_locationData!.latitude, _locationData!.longitude);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: latLng,
            zoom: 14.0,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('job_location'),
              position: latLng,
              infoWindow: InfoWindow(
                title: 'Job Location',
                snippet: _locationData!.formattedAddress,
              ),
            ),
          },
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          tiltGesturesEnabled: false,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: false,
        ),
        
        // Tap overlay to open in external maps
        Positioned.fill(
          child: GestureDetector(
            onTap: _openInMaps,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // "View in Maps" button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _openInMaps,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.open_in_new,
                    size: 12,
                    color: Color(0xFF7551FF),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'View',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7551FF),
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}