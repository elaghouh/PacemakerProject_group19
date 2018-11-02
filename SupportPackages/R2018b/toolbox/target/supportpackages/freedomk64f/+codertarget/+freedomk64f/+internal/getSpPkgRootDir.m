function rootDir = getSpPkgRootDir()
%GETSPPKGROOTDIR Return the root directory of this support package

%   Copyright 2015 The MathWorks, Inc.

rootDir = fileparts(strtok(mfilename('fullpath'), '+'));
end

