function pinmapOpenFcn(action)
%PINMAPOPENFCN Open the GPIO Pin Map diagram for FRDM-K64F Board

% Copyright 2015-2018 The MathWorks, Inc.

persistent imageHandle;
switch action
    case 'open'
        if isempty(imageHandle) || ~ishandle(imageHandle)
            scrsz = get(groot,'ScreenSize');            
            h = figure('Position',[scrsz(4)/2 scrsz(4)/4 scrsz(3)/2 scrsz(4)/2]);
            imageHandle = h;
        else
            h = imageHandle;
        end    
        figure(h);
        image(imread(fullfile(codertarget.freedomk64f.internal.getSpPkgRootDir, 'resources', 'k64f_pinlayout.png')));
        set(gca, 'LooseInset', get(gca, 'TightInset'));
        set(h, 'Name', 'GPIO Pin Map', 'NumberTitle', 'off','Toolbar','none');
        axis('off');
        axis('equal');
    case 'close'
        if ishandle(imageHandle)
            h = imageHandle;
            close(h);
        end
end

end