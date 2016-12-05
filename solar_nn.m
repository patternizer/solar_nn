function solar_nn.m

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	  % solar_nn.m calculates total surface solar radiation [W/m2]     %
    % Copyright (C) 2016 M. Taylor 								                   %
    %                                                                %
	  % This program is free software: you can redistribute it and/or  %
	  % modify it under the terms of the GNU General Public License as %
	  % published by the Free Software Foundation, either version 3 of %
	  % the License, or (at your option) any later version.			       %
    %                                                                %
    % This program is distributed in the hope that it will be useful %
	  % but WITHOUT ANY WARRANTY; without even the implied warranty of %
	  % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.			     %
	  % See the GNU General Public License for more details.			     %
    %                                                                %
    % You should have received a copy of the GNU General Public 	   %
	  % License along with this program. 								               %
	  % If not, see http://www.gnu.org/licenses/.						           %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SYNTAX:                                                        %
    % >> solar_nn                                                    %
    %                                                                %
    % OUTPUT:                                                        %
    % spectrally-integrated (285-2600nm) GHI [W/m2]                  %
    %                                                                %
    % CODE DEPENDENCY LIST: see DEPENDENCIES                         %
    %                                                                %
    % INPUT FILES:                                                   %
    % MSG COT files: TEST_DATA/*.COT                                 %
    % MSG h5 files: TEST_DATA/*.h5                                   %
    % CAMS AOD files: TEST_DATA/*.mat                                %
    % LAT_LON.mat meshgrid of lat-lon coordinates                    %
    %                                                                %
    % INPUT VARIABLES:                                               %
    % ICOT  --> liquid cloud optical thickness                       %
    % WCOT  --> liquid cloud optical thickness                       %
    % OZO   --> total columnar ozone [>= 0.0 D.U.]                   %
    % SZA   --> solar zenith angle                                   %
    % AOD   --> aerosol optical depth                                %
    % AEX   --> Angstrom exponent (470-870nm)                        %
    % SSA   --> single scattering albedo                             %
    % H2O   --> columnar precipitable water [cm]                     %
    %                                                                %
    % DERIVED VARIABLES:                                             %
    % lon   --> longitude [-180,180] degrees                         %
    % lat   --> latitude [-90,90]                                    %
    % yyyy  --> year                                                 %
    % mm    --> month                                                %
    % dd    --> day of month                                         %
    % HH    --> hour of day                                          %
    % MM    --> time of the day [0,1440] minutes                     %
    % doy   --> day of the year [1,366]                              %
    % SZA   --> solar zenith angle                                   %
    %                                                                %
    % VERSION: 	1.0 (05/12/2016)    				                         %
    %                                                                %
    % CONTACT: 	M. Taylor (patternizer AT gmail DOT com)   			     %
    %                                                                %
    % ACKNOWLEDGEMENTS:                                              %
    % Many thanks to P.G. Kosmopoulos (NOA) for kindly preparing the %
    % look-up tables used to train the neural networks net_clear.mat %
    % and net_cloud.mat and to S. Kazadzis (WRC/PMOD) for scientific %
    % input and guidance.                                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all; clear all; clc;

font_size = 14;
font_weight = 'bold';
line_width = 1;
cmin = 0.0;    % minimum total radiance
cmax = 1250.0; % maximum total radiance

d = 'TEST_DATA/';
d_COT = strcat(d,'*.COT'); % COT output files from MSG
d_h5 = strcat(d,'*.h5'); % h5 output files from MSG
d_AOD = strcat(d,'*.mat'); % AOD output files from CAMS

Files_COT = struct2cell(dir(d_COT));
Files_h5 = struct2cell(dir(d_h5));
Files_AOD = struct2cell(dir(d_AOD));
Filenames_COT = Files_COT(1,1:end)';
Filenames_h5 = Files_h5(1,1:end)';
Filenames_AOD = Files_AOD(1,1:end)';
nFiles = length(Filenames_COT);

for k = 1:nFiles

    nameinput = []; timestamp = []; cloudphase = [];
    nameinput = Filenames_COT{k};
    timestamp = nameinput(1:12)
    Filename_h5 = Filenames_h5{k};
    cloudphase = hdf5read(fullfile(d,Filename_h5),'/CT_PHASE');
    temp1 = fliplr(rot90(reshape(cloudphase,2116,1232),3));
    temp2 = temp1(695:1012,1142:1585);
    cloudphase = temp2(:);
    idx_clear = find(cloudphase == 0 | cloudphase == 3);
    idx_cloud = find(cloudphase == 1 | cloudphase == 2);

    fileID = fopen(fullfile(d,nameinput));
    A = fread(fileID,'ushort');
    B = fliplr(rot90(reshape(A,2116,1232),3)); % rotate anti-clockwise 1*90 = 90 degrees
    B = B(695:1012,1142:1585);
    A = B(:); clear B;
    A(A == 32767) = 0.0;
    A = A / 10.0;
    A(A > 20.0) = 20.0; % quench at maximum COT = 20.0
    n = size(A);
    if sum(A) == 0.0
        continue
    else
    end
    fclose(fileID);

    WCOT = A;
    ICOT = zeros(size(A));        % no ice cloud
    OZO  = ones(size(A)) * 350.0; % climatological value
    for j = 1:length(Filenames_AOD)
        temp = Filenames_AOD{j};
        temp1 = str2num(nameinput(9:10)) * 60 + str2num(nameinput(11:12));
        temp2 = (str2num(temp(9:13))-24) * 60;
        if temp2 < (temp1 + (3 * 60))
            load(fullfile(d,Filenames_AOD{j}));
            AOD = aod(695:1012,1142:1585);
            AOD = AOD(:);
            AOD_median = ignoreNaN(AOD,@median);
        else
            continue
        end
    end
    if exist('AOD');
    else
        AOD  = ones(size(A)).*0.3; % climatological value
    end
    SSA  = ones(size(A)).*0.9; % climatological value
    H2O  = ones(size(A)).*1.0; % climatological value
    AEX  = ones(size(A)).*0.4; % climatological value

    yyyy = str2num(nameinput(1:4));
    mm = str2num(nameinput(5:6));
    dd = str2num(nameinput(7:8));
    HH = str2num(nameinput(9:10));
    MM = str2num(nameinput(11:12));
    doy = floor(datenum(yyyy,mm,dd) - datenum(yyyy,01,01)) + 1;
    date_vec = [mm dd yyyy];
    Date = strcat(['',nameinput(5:6),'/',nameinput(7:8),'/',nameinput(1:4),'']);
    Daylight_Savings = is_Daylight_Savings(Date);
    if Daylight_Savings == 1
        correction = 1;
    else
        correction = 0;
    end
    h = HH + 2 + correction;
    if (h - 24 >= 0)
        h = h - 24.0;
    end
    m = MM + HH * 60;
    if HH + 2 + correction >= 24
        Date = datestr(datenum(Date)+1,'dd/mm/yyyy');
    end
    if length(num2str(h)) == 1
        str_HH = strcat(['0',num2str(h)]);
    else
        str_HH = num2str(h);
    end
    if length(num2str(MM)) == 1
        str_MM = strcat([num2str(MM),'0']);
    else
        str_MM = num2str(MM);
    end
    datestring = strcat([Date,'  ',str_HH,':',str_MM]);

    load('LAT_LON.mat'); % lat[200x290],lon[200x290]
    LON = lon(:);
    LAT = lat(:);
    SZA = zeros(size(A));
    for i = 1:length(A)
        SZA(i,1) = sz_angle(yyyy,m,doy,LAT(i),-LON(i));
    end
    clear LAT LON lat lon

    load('net_cloud.mat'); % cloud NN
    net_cloud = net; % ICOT,WCOT,SZA,OZO
    load('net_clear.mat'); % clear NN
    net_clear = net; % AOD,SSA,SZA,OZO,H2O,AEX

    INPUTS_AEROSOL = [AOD,SSA,SZA,OZO,H2O,AEX]';  % clear sky NN
    INPUTS_AEROSOL0 = [zeros(size(AOD)),SSA,SZA,OZO,H2O,AEX]';  % clear sky NN (no aerosol)
    y_AEROSOL = sim(net_clear,INPUTS_AEROSOL);
    y_AEROSOL(y_AEROSOL < 0) = 0.0;
    y_AEROSOL0 = sim(net_clear,INPUTS_AEROSOL0);
    y_AEROSOL0(y_AEROSOL0 < 0) = 0.0;
    GHI_AEROSOL = 5.0 * trapz(y_AEROSOL)/1000.0;
    GHI_AEROSOL0 = 5.0 * trapz(y_AEROSOL0)/1000.0;

    INPUTS_CLOUD = [ICOT,WCOT,SZA,OZO]'; % cloudy sky NN
    INPUTS_CLOUD0 = [ICOT,zeros(size(WCOT)),SZA,OZO]'; % cloudy sky NN (no cloud)
    if isequal(numel(find(A(:)>0)),0)
		y_CLOUD = y_AEROSOL;
		y_CLOUD0 = y_AEROSOL0;
	else
		y_CLOUD = sim(net_cloud,INPUTS_CLOUD);
		y_CLOUD(y_CLOUD < 0) = 0.0;
		y_CLOUD0 = sim(net_cloud,INPUTS_CLOUD0);
		y_CLOUD0(y_CLOUD0 < 0) = 0.0;
    end
    scalefactor = max(y_AEROSOL0(:))/max(y_CLOUD0(:)); % NB: match clear sky conditions for both NN
    y_CLOUD = y_CLOUD * scalefactor;
    y_CLOUD0 = y_CLOUD0 * scalefactor;
    GHI_CLOUD = 5.0 * trapz(y_CLOUD)/1000.0;
	  GHI_CLOUD0 = 5.0 * trapz(y_CLOUD0)/1000.0;
    GHI = GHI_CLOUD;
    GHI(idx_clear) = GHI_AEROSOL(idx_clear);
	  AMF = (GHI_AEROSOL0-GHI_AEROSOL)./GHI_AEROSOL0; % aerosol modification factor
	  CMF = (GHI_CLOUD0-GHI_CLOUD)./GHI_CLOUD0;       % cloud modification factor

    load('LAT_LON.mat'); % lat[200x290],lon[200x290]
    Lon = lon(:);
    Lat = lat(:);
    latlim = [min(lat(:)) max(lat(:))];
    lonlim = [min(lon(:)) max(lon(:))];

    figure; set(gcf, 'color','white', 'visible','on','units','normalized','outerposition',[0 0 1 1]);
    m_proj('lambert','lon',lonlim,'lat',latlim);
    m_gshhs('i','save','coastline'); % intermediate resolution
    m_pcolor(lon,lat,reshape(GHI,318,444)); shading flat;
    m_usercoast('coastline','linewidth',1,'color','k');
    m_grid('box','fancy','tickdir','in','fontsize',font_size);
    rgbmap('dark blue','light blue','light green','yellow','magenta','white');
    caxis([cmin,cmax]);
    CB = colorbar('FontName','Times','FontSize',font_size,'Location','EastOutside');
    set(get(CB,'YLabel'),'String','GHI [W/m^{2}]','FontName','Times','FontSize',font_size);
    xlabel('LON','FontSize',font_size,'FontWeight',font_weight);
    ylabel('LAT','FontSize',font_size,'FontWeight',font_weight);
    title({'';'TOTAL SURFACE SOLAR RADIATION';datestring},'FontName','Times','FontSize',font_size);
    set(gca,'FontName','Times','FontSize',font_size);
    ha = gca; uistack(ha,'bottom');
    print('-djpeg','-r300',strcat(['GHI_',nameinput(1:12)]));
    close;

    OUTPUTS_AEROSOL = [GHI_AEROSOL',GHI_AEROSOL0',AMF'];
    OUTPUTS_CLOUD = [GHI_CLOUD',GHI_CLOUD0',CMF'];
    save(strcat(['RUN_',nameinput(1:12)]),'Lat','Lon','GHI','INPUTS_AEROSOL','INPUTS_CLOUD','OUTPUTS_AEROSOL','OUTPUTS_CLOUD');

    end
 end
