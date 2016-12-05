function [za] = sz_angle(y,t0,jd,la,lo)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	  % [za] = sz_angle(y,t0,jd,la,lo)                                 %
    % calculates the solar zenith angle                              %
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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % FUNCTION: sz_angle.m                                 %
    %                                                      %
    % Version notes:                                       %
    %                                                      %
    % Brewer BASIC code ported to MATLAB as brewersza.m    %
    % Modified by M. Taylor: patternizer@gmail.com         %
    %                                                      %
    % Latest Version: 1.1 05/12/2016                       %
    % Date:           05/12/2016                           %
    % Contact: M. Taylor (patternizer AT gmail DOT com)    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    ep = 0.999999999;
    p0 = pi / 180;
    t = zeros(length(y),1);
    leap = find(jd(:) < 61 & y(:) / 4 == fix(y(:)/ 4));
    if ~isempty(leap)
        t(leap) = -1;
    end
    sj = zeros(length(y),1);
    leap2 = find(jd > 60 & y/ 4 == fix(y / 4));
    if ~isempty(leap2)
        sj(leap2) = -1;
    end
    t = (t + fix((y - 1900) / 4) + (y - 1965) * 365 - 16 + (jd + sj)) / 365.2422;
    i = (279.4574 + 360 * t + t0 / 1460.97) * p0;
    e = 4.2 * sin(3 * i) - 2 * cos(2 * i) + 596.5 * sin(2 * i);
    e = e - 12.8 * sin(4 * i) + 19.3 * cos(3 * i);
    e = e - (102.5 + 0.142 * t) .* sin(i) + (0.033 * t - 429.8) .* cos(i);
    ra = (t0 + e / 60 + 720 - lo * 4) * p0 / 4;
    a = atan(0.4336 * sin(i - e * p0 / 240));
    e = cos(ra) .* cos(a) * cos(la * p0) + sin(la * p0) * sin(a);
    res1 = find(e >= 1);
    if ~isempty(res1)
        e(res1) = ep;
    end
    res2 = find(e <= -1);
    if ~isempty(res2)
        e(res2) = -ep;
    end
    e = atan(sqrt(1 - e .* e) ./ e);
    res4 = find(e<0);
    if ~isempty(res4)
        e(res4)=e(res4)+pi;
    end
    ra = sin(ra);
    m2 = 0.999216 * sin(e);
    m2 = 1./ cos(atan(m2 ./ sqrt(1 - m2 .* m2)));
    m2 = round(1000 * m2) / 1000;
    M3 = m2;
    m2 = 0.99656 * sin(e);
    m2 = 1 ./ cos(atan(m2 ./ sqrt(1 - m2.* m2)));
    m2 = round(1000 * m2) / 1000;
    res5 = find(e<=90.5 * p0);
    c1 = zeros(length(e),1);
    d1 = zeros(length(e),1);
    if ~isempty(res5)
        c1(res5) = cos(e(res5));
        d1(res5) = 1 ./ (0.955 + (20.267 * c1(res5))) - 0.047121;
        c1(res5) = c1(res5) + 0.0083 * d1(res5);
        res6 = find(c1(res5)>-ep & c1(res5)<ep);
        if ~isempty(res6)
             e(res5(res6)) = pi / 2 - atan(c1(res5(res6)) ./ sqrt(1 - c1(res5(res6)) .* c1(res5(res6))));
        end
    end
    za = fix(1000 * e / p0 + 0.5) / 1000;

end
