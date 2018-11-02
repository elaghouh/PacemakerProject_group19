function out = getKinetisSDKRootDir
%GETKINETISSDK gets the location of the Kinetis SDK
%that is registered using Hardware Setup Screens

%   Copyright 2015-2017 The MathWorks, Inc.
lName = 'Kinetis SDK';
out = [];
targetFolder = codertarget.target.getTargetFolder('Freescale FRDM-K64F Board');
tpFileName = codertarget.target.getThirdPartyToolsRegistrationFileName(targetFolder);
if exist(tpFileName, 'file')
    h = codertarget.thirdpartytools.ThirdPartyToolInfo(tpFileName);
    thirdPartyToolsInfo = h.getThirdPartyTools();
    thirdPartyToolsInfo = [thirdPartyToolsInfo{:}];
    thirdPartyToolsInfo = [thirdPartyToolsInfo{:}];
    idx = ismember({thirdPartyToolsInfo.ToolName}, lName);
    out = thirdPartyToolsInfo(idx).RootFolder;
end
end