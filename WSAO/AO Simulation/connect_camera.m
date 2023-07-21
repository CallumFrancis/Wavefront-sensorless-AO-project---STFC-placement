
% Connecting to camera
%cam = gigecam('169.254.148.123');
cam = gigecam('130.246.68.1');
cam.ExposureTimeAbs = 5000;
cam.Timeout = 2;
preview(cam)
