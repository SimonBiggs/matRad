function [ dose ] = matRad_interpDicomDoseCube( ct, currDose )
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% matRad function to interpolate a given Dicom Dose Cube dicom RTDOSE data
%
% call
%   [ dose ] = matRad_interpDicomDoseCube( ct, currDose )
%
% input
%   ct:             ct imported by the matRad_importDicomCt function
%   currDose:   	  one (of several) dose cubes which should be interpolated
%
% output
%   dose:           struct with different actual current dose cube and several
%                   meta data
%
% References
%   -
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015 the matRad development team.
%
% This file is part of the matRad project. It is subject to the license
% terms in the LICENSE file found in the top-level directory of this
% distribution and at https://github.com/e0404/matRad/LICENSES.txt. No part
% of the matRad project, including this file, may be copied, modified,
% propagated, or distributed except according to the terms contained in the
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% read information out of the RT file
dosefile = currDose{1};
doseInfo = dicominfo(dosefile);

% read the dosefile itself
dosedata = dicomread(dosefile);
% convert 16-bit integer to double precision, therefore to 1 normalized
dosedata = im2double(dosedata);

% give it an internal name
dose.internalName = currDose{12};

% read out the resolution
dose.resolution.x = doseInfo.PixelSpacing(1);
dose.resolution.y = doseInfo.PixelSpacing(2);
dose.resolution.z = doseInfo.SliceThickness;

% target resolution is ct.resolution
target_resolution = ct.resolution;

% convert dosedata to 3-D cube
dose.cube = squeeze(dosedata(:,:,1,:));

% ct resolution is target resolution, now convert to new cube;

% generating grid vectors
x = doseInfo.ImagePositionPatient(1) + doseInfo.PixelSpacing(1) * double([0:doseInfo.Columns - 1]);
y = doseInfo.ImagePositionPatient(2) + doseInfo.PixelSpacing(2) * double([0:doseInfo.Rows - 1]);
z = [doseInfo.ImagePositionPatient(3) + doseInfo.GridFrameOffsetVector];

% new vectors
xq = [min(ct.x) : target_resolution.x : max(ct.x)];
yq = [min(ct.y) : target_resolution.y : max(ct.y)];
zq =  min(ct.z) : target_resolution.z : max(ct.z);

% set up grid matrices - implicit dimension permuation (X Y Z-> Y X Z)
% Matlab represents internally in the first matrix dimension the
% ordinate axis and in the second matrix dimension the abscissas axis
[ Y,  X,  Z] = meshgrid(x,y,z);
[Yq, Xq, Zq] = meshgrid(xq,yq,zq);

% scale cube from relative (normalized) to absolute values
% need BitDepth
bitDepth = double(doseInfo.BitDepth);
% get GridScalingFactor
gridScale = double(doseInfo.DoseGridScaling);
% CAUTION: Only valid if data is converted via im2double
doseScale = (2 ^ bitDepth - 1) * gridScale;
% rescale dose.cube
dose.cube = doseScale * dose.cube;

% interpolation to ct grid - cube is now stored in Y X Z
dose.cube = interp3(Y,X,Z,dose.cube,Yq,Xq,Zq,'linear',0);

% write new parameters
dose.resolution = ct.resolution;
dose.x = xq;
dose.y = yq;
dose.z = zq;

% check whether grid position are the same as the CT grid positions are
if ~(isequal(dose.x,ct.x) && isequal(dose.y,ct.y) && isequal(dose.z,ct.z))
    errordlg('CT-Grid and Dose-Grid are still not the same');
end

% write Dicom-Tags
dose.dicomInfo.PixelSpacing            = [target_resolution.x; ...
                                                target_resolution.y];
dose.dicomInfo.ImagePositionPatient    = [min(dose.x); min(dose.y); min(dose.z)];
dose.dicomInfo.SliceThickness          = target_resolution.z;
dose.dicomInfo.ImageOrientationPatient = doseInfo.ImageOrientationPatient;
dose.dicomInfo.DoseType                = doseInfo.DoseType;
dose.dicomInfo.DoseSummationType       = doseInfo.DoseSummationType;
dose.dicomInfo.InstanceNumber          = doseInfo.InstanceNumber;
dose.dicomInfo.SOPClassUID             = doseInfo.SOPClassUID;
dose.dicomInfo.SOPInstanceUID          = doseInfo.SOPInstanceUID;
dose.dicomInfo.ReferencedRTPlanSequence = doseInfo.ReferencedRTPlanSequence;

end
