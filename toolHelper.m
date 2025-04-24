classdef toolHelper

    properties

    end

    methods (Static)
        function faceColors = prop2color(colorRange, propValues);
            faceColors = prop2color(colorRange, propValues);
        end

        function [nwk1] = makeSubNwkInd(nwk, faceSelection);
            [nwk1] = makeSubNwkInd(nwk, faceSelection);
        end

        function [faceList] = faceEditCb(input_str, nwk);
            [faceList] = faceEditCb(input_str, nwk);
        end

        function [ptsList] = ptEditCb(input_str, nwk);
            [ptsList] = ptEditCb(input_str, nwk);
        end

        function [subnwk] = faceOrPtSelections(faceSelection, ptSelection, nwk);
            [subnwk] = faceOrPtSelections(faceSelection, ptSelection, nwk);
        end

        function [subnwk] = faceAndPtSelections(faceSelection, ptSelection, nwk);
            [subnwk] = faceAndPtSelections(faceSelection, ptSelection, nwk);
        end

        function [new_nwk] = removeFacesNwk(nwk, faceIndices);
            [new_nwk] = removeFacesNwk(nwk, faceIndices);
        end
    
    end
end

function faceColors = prop2color(colorRange, propValues)
    normalizedProps = (propValues - min(propValues)) / (max(propValues) - min(propValues));
    colorIndices = min(round(normalizedProps * (size(colorRange, 1)-1)) + 1, size(colorRange, 1));
    faceColors = colorRange(colorIndices, :);
end


function [nwk1] = makeSubNwkInd(nwk, faceSelection);
        
    nwk1 = [];
    nwk1.nf = size(faceSelection, 1);
    nwk1.dia = nwk.dia(faceSelection);

    uniquePts = unique(nwk.faceMx(faceSelection, 2:3));
    nwk1.ptCoordMx = nwk.ptCoordMx(uniquePts, :);
    nwk1.pIdx = uniquePts; nwk1.np = size(nwk1.ptCoordMx,1);
    
    nwk1.fIdx = faceSelection;
    nwk1.faceMx = nwk.faceMx(faceSelection, :);
    [~, nwk1.faceMx(:,2)] = ismember(nwk1.faceMx(:,2), nwk1.pIdx);
    [~, nwk1.faceMx(:,3)] = ismember(nwk1.faceMx(:,3), nwk1.pIdx);
end


function [subnwk] = faceAndPtSelections(faceSelection, ptSelection, nwk)

    if (isempty(faceSelection) && isempty(ptSelection))
        subnwk = nwk; return;
    end

    subnwk = [];

    % Faces that have atleast one endpoint in selected points - use all or any function
    endpoints = nwk.faceMx(faceSelection, 2:3);
    validFaces = any(ismember(endpoints, ptSelection), 2);
    filteredFacesList = faceSelection(validFaces);
    
    if ~isempty(filteredFacesList)
        uniquePts = unique(nwk.faceMx(filteredFacesList, 2:3));

        subnwk.fIdx = filteredFacesList; subnwk.nf = size(filteredFacesList, 1);
        subnwk.faceMx = nwk.faceMx(filteredFacesList, :);
        [~, subnwk.faceMx(:,2)] = ismember(nwk.faceMx(filteredFacesList, 2), uniquePts);
        [~, subnwk.faceMx(:,3)] = ismember(nwk.faceMx(filteredFacesList, 3), uniquePts);

        subnwk.ptCoordMx = nwk.ptCoordMx(uniquePts, :);
        subnwk.pIdx = uniquePts; subnwk.np = size(subnwk.ptCoordMx,1);
        subnwk.dia = nwk.dia(filteredFacesList);
    end

end

function [subnwk] = faceOrPtSelections(faceSelection, ptSelection, nwk)

    if (isempty(faceSelection) && isempty(ptSelection))
        subnwk = nwk; return;
    end

    subnwk = []; uniquePts = [];
    if ~isempty(faceSelection)
        uniquePts = unique(nwk.faceMx(faceSelection, 2:3));

        subnwk.fIdx = faceSelection; subnwk.nf = size(faceSelection, 1);
        subnwk.faceMx = nwk.faceMx(faceSelection, :);
        [~, subnwk.faceMx(:,2)] = ismember(nwk.faceMx(faceSelection, 2), uniquePts);
        [~, subnwk.faceMx(:,3)] = ismember(nwk.faceMx(faceSelection, 3), uniquePts);

        subnwk.ptCoordMx = nwk.ptCoordMx(uniquePts, :);
        subnwk.pIdx = uniquePts; subnwk.np = size(subnwk.ptCoordMx,1);
        subnwk.dia = nwk.dia(faceSelection);
    end

    if ~isempty(ptSelection)
        diffPtsList = setdiff(ptSelection, uniquePts);
        
        if (~isfield(subnwk, 'ptCoordMx')); subnwk.ptCoordMx = []; end
        if (~isfield(subnwk, 'pIdx')); subnwk.pIdx = []; end

        subnwk.ptCoordMx = [subnwk.ptCoordMx ; nwk.ptCoordMx(diffPtsList, :)];
        subnwk.np = size(subnwk.ptCoordMx, 1);
        subnwk.pIdx = [subnwk.pIdx; diffPtsList];

        if (~isfield(subnwk, 'faceMx'))
            subnwk.faceMx = []; subnwk.nf = 0;
            subnwk.dia = []; subnwk.fIdx = [];
        end
    end

end

function [faceList] = faceEditCb(input_str, nwk)

    %input_str = strjoin(faceEditValue, ''); for uicontrol obj, its already a string not cell
    input_str = strrep(input_str, ' ', '');
    input_values = strsplit(input_str, ',');
    
    faceList = [];
    
    for i = 1:numel(input_values)
        value = input_values{i};
        
        if contains(value, '&')
            conditions = strsplit(value, '&');
            tempFaceList = 1:nwk.nf;
            for j = 1:numel(conditions)
                condition = conditions{j};
                tempFaceList = intersect(tempFaceList, parseFaceCondition(nwk, condition));
            end
            faceList = union(faceList, tempFaceList);
        else
            faceList = union(faceList, parseFaceCondition(nwk, value));
        end
    end

    if ~isempty(faceList)
        faceList = sort(faceList, 1);
    end
end

function indices = parseFaceCondition(nwk, condition)
    indices = [];
    if contains(condition, ':')
        range_values = str2num(condition);
        indices = range_values;
    else
        operator = '';
        if contains(condition, '>')
            operator = '>';
            value = str2double(condition(strfind(condition, '>') + 1:end));
        elseif contains(condition, '<')
            operator = '<';
            value = str2double(condition(strfind(condition, '<') + 1:end));
        elseif contains(condition, '=')
            operator = '=';
            value = str2double(condition(strfind(condition, '=') + 1:end));
        end
        
        if startsWith(condition, 'f')
            if strcmp(operator, '>')
                indices = (value+1):nwk.nf;
            elseif strcmp(operator, '<')
                indices = 1:(value-1);
            end

        elseif any(startsWith(condition, {'d', 'l', 'g', 'p1', 'p2', 'ls'}))

             if strcmp(condition(1), 'd')
                searchCol = nwk.dia;
             
             elseif strcmp(condition(1:2), 'ls')
                 if isfield(nwk, 'ls')
                     searchCol = nwk.ls;
                 else
                     disp('.ls file not found');
                     return;
                 end

             elseif strcmp(condition(1), 'l')
                if ~isfield(nwk, 'faceLen')
                    nwk.faceLen = calculateLengths(nwk);
                end
                searchCol = nwk.faceLen;     
             elseif strcmp(condition(1), 'g')
                searchCol = nwk.faceMx(:, 1);
             elseif strcmp(condition(1:2), 'p1')
                searchCol = nwk.faceMx(:, 2);
             elseif strcmp(condition(1:2), 'p2')
                searchCol = nwk.faceMx(:, 3);
             end
      
             if strcmp(operator, '=')
                indices = find(searchCol == value);
             elseif strcmp(operator, '>')
                indices = find(searchCol > value);
             elseif strcmp(operator, '<')
                indices = find(searchCol < value);
             end

        else

            index = str2double(condition);
            if ~isnan(index) && index >= 1 && index <= nwk.nf
                indices = index;
            elseif ~isempty(condition)
                disp(['Invalid input: ', condition]);
            end
        end
    end
end

function [ptsList] = ptEditCb(input_str, nwk)
    % input_str = strjoin(ptEditBox.Value, ''); for uicontrol obj, its already a string not cell
    input_str = strrep(input_str, ' ', '');  % Remove whitespace
    input_values = strsplit(input_str, ',');  % Split by comma
    
    ptsList = [];        
    for i = 1:numel(input_values)
        value = input_values{i};
        
        if contains(value, '&')
            conditions = strsplit(value, '&');
            tempPtsList = 1:nwk.np;
            for j = 1:numel(conditions)
                condition = conditions{j};
                tempPtsList = intersect(tempPtsList, parsePtCondition(nwk, condition));
            end
            ptsList = union(ptsList, tempPtsList);
        else
            ptsList = union(ptsList, parsePtCondition(nwk, value));
        end
    end

    if ~isempty(ptsList)
        ptsList = sort(ptsList, 1);
    end
end

function indices = parsePtCondition(nwk, condition)
    indices = [];
    if contains(condition, ':')
        range_values = str2num(condition);
        indices = range_values;
    else
        operator = '';
        if contains(condition, '>')
            operator = '>';
            value = str2double(condition(strfind(condition, '>') + 1:end));
        elseif contains(condition, '<')
            operator = '<';
            value = str2double(condition(strfind(condition, '<') + 1:end));
        elseif contains(condition, '=')
            operator = '=';
            value = str2double(condition(strfind(condition, '=') + 1:end));
        end
        
        if startsWith(condition, 'p')

            if strcmp(operator, '>')
                indices = (value+1):nwk.np;
            elseif strcmp(operator, '<')
                indices = 1:(value-1);
            elseif contains(condition, '%')
                indices = value:value:nwk.np;
            end

        elseif any(startsWith(condition, {'X', 'Y', 'Z', 'DGi', 'DGo'}))

            if strcmp(condition(1), 'X')              
                searchCol = nwk.ptCoordMx(:, 1);                
            elseif strcmp(condition(1), 'Y')                    
                searchCol = nwk.ptCoordMx(:, 2);
            elseif strcmp(condition(1), 'Z')
                searchCol = nwk.ptCoordMx(:, 3);
            elseif strcmp(condition(1:3), 'DGi')
                if ~isfield(nwk, 'inDeg')
                    [nwk.inDeg, nwk.outDeg] = calculateInOutDegree(nwk);
                end
                searchCol = nwk.inDeg;
            elseif strcmp(condition(1:3), 'DGo')
                if ~isfield(nwk, 'outDeg')
                    [nwk.inDeg, nwk.outDeg] = calculateInOutDegree(nwk);
                end
                searchCol = nwk.outDeg;
            end

            if strcmp(operator, '=')
                indices = find(searchCol == value);
            elseif strcmp(operator, '>')
                indices = find(searchCol > value);
            elseif strcmp(operator, '<')
                indices = find(searchCol < value);
            end

        else

            index = str2double(condition);
            if ~isnan(index) && index >= 1 && index <= nwk.np
                indices = index;
            elseif ~isempty(condition)
                disp(['Invalid input: ', condition]);
            end
        
        end
    end
end

function lengths = calculateLengths(nwk)
    numFaces = size(nwk.faceMx, 1);
    lengths = zeros(numFaces, 1);
    for k = 1:numFaces
        pt1 = nwk.ptCoordMx(nwk.faceMx(k, 2), :);
        pt2 = nwk.ptCoordMx(nwk.faceMx(k, 3), :);
        lengths(k) = sqrt(sum((pt1 - pt2).^2));
    end
end

function [inDeg, outDeg] = calculateInOutDegree(nwk)
     C1 = nwkSim.ConnectivityMx(nwk.nf, nwk.np, nwk.faceMx);
     [inDeg, outDeg] = nwkHelp.getNodeDegrees(nwk, C1);
end

function [nwk] = removeFacesNwk(nwk, faceIndices)
     nwk.faceMx(faceIndices, :) = [];
     nwk.dia(faceIndices, :) = [];
     nwk.nf = size(nwk.faceMx, 1);
     nwk.nt = (nwk.np + nwk.nf);
end
