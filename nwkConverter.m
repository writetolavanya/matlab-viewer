 classdef nwkConverter

    properties

    end

    methods (Static)
        function [nwk] = stl2faceMx3(filePath);
            [nwk.ptCoordMx, nwk.faceMx3, nwk.np, nwk.nf, nwk.nt, nwk.dia] = stl2faceMx3(filePath);
        end
        
        function [nwk] = stl2faceMx2(filePath);
            [nwk.ptCoordMx, nwk.faceMx, nwk.np, nwk.nf, nwk.nt, nwk.dia] = stl2faceMx2(filePath);
        end

        function [nwk] = msh2nwk(filePath);
            [nwk] = msh2nwk(filePath);
        end

        function nwk2nwkx(filePath);
            nwk2nwkx(filePath);
        end

    end
end

function [ptCoordMx, faceMx3, np, nf, nt, dia] = stl2faceMx3(filePath)

        [TR, ~, ~, ~] = stlread(filePath);
        ptCoordMx = TR.Points;
        edgesMx = TR.ConnectivityList;
        nf = size(edgesMx, 1);
        faceMx3 = zeros(nf, 6);
        faceMx3(:, 2:4) = edgesMx;
        
        np = length(ptCoordMx(:,1));
        nt = np + nf;
        dia = ones(nf, 1);
end

function [ptCoordMx, faceMx, np, nf, nt, dia] = stl2faceMx2(filePath)

        [TR, ~, ~, ~] = stlread(filePath);
        ptCoordMx = TR.Points;
        edgesMx = edges(TR);
        nf = size(edgesMx, 1);
        faceMx = zeros(nf, 5);
        faceMx(:, 2:3) = edgesMx;
        
        np = length(ptCoordMx(:,1));
        nt = np + nf;
        dia = ones(nf, 1);
end

function [nwk] = msh2nwk(filePath)    

    fid = fopen(filePath, 'r');
    if fid == -1
        error('Could not open the Gambit mesh file.');
    end

    ptCoordMx = [];
    faceMx = [];

    [~, fileName, ~] = fileparts(filePath);
    pMxFile = strcat(fileName, '.pMx');
    ptFid = fopen(pMxFile, 'w');

    fMxFile = strcat(fileName, '.fMx');
    faceFid = fopen(fMxFile, 'w');

    while ~feof(fid)
        line = fgetl(fid);
    
        if contains(regexprep(line, '\s+', ''), '(10(0')
            line = fgetl(fid);
            np = sscanf(line, '(10 (%*x %*x %x %*x %*x)');

            nextLine = fgetl(fid);
            while startsWith(strtrim(nextLine), '(')
                nextLine = fgetl(fid);
            end

            lines_cell = [{nextLine}, textscan(fid, '%s', np-1, 'Delimiter', '\n')];
            lines_str = [string(lines_cell{1}); string(lines_cell{2})];
  
            fprintf(ptFid, '%s\n', lines_str);
            fclose(ptFid);
        end
        
        if contains(regexprep(line, '\s+', ''), '(13(0')
            % Extract the range of face indices in the entire mesh
            range = sscanf(line, '(13 (0 %x %x %*x)');
            numFaces = range(2) - range(1) + 1;
            groupId = 0;
    
            while ~feof(fid)
                line = fgetl(fid);
                if contains(regexprep(line, '\s+', ''), '(13(')
    
                    % Extract the range of face indices in the current group
                    groupLine = sscanf(line, '(13 (%*x %x %x %*x)');
                    groupId = groupId + 1;
                    groupNumFaces = groupLine(2) - groupLine(1) + 1;
    
                    % Read the face data for the current group
                    for i = 1:groupNumFaces
                        line = fgetl(fid);
                        faceData = sscanf(line, '%x %x %x %x %x %*x');
    
                        if length(faceData) > 4   
                            fprintf(faceFid, '%d %d %d %d %d %d\n', groupId, faceData(1), faceData(2), faceData(3), 0, 0);
                        elseif faceData(1) == 2
                            fprintf(faceFid, '%d %d %d %d %d\n', groupId, faceData(2), faceData(3), 0, 0);
                        elseif faceData(1) == 3
                            fprintf(faceFid, '%d %d %d %d %d %d\n', groupId, faceData(2), faceData(3), faceData(4), 0, 0);
                        end    
                    end
                end
            end
            fclose(faceFid);
        end

        % starts at )) and faces line, convert to fMx
        % check the pdf for multiple formats
        % remove the last blank line in .pMx file
        
    end

    % faceMx = load(fMxFile);
    % ptCoordMx = load(pMxFile);
    % np = size(ptCoordMx, 1); nf = size(faceMx, 1); nt = np + nf;
    % dia = ones(nf, 1);
    nwk = nwkHelp.load(fileName);
end
