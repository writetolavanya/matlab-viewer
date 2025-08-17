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

        function [collData, errMsg] = parseCollectionFile(collFullPath);
            [collData, errMsg] = parseCollectionFile(collFullPath);
        end

        function colorRGB = validateColor(colorName);
            colorRGB = validateColor(colorName);
        end

        function [absPath, found] = resolveFilePath(filePath);
             [absPath, found] = resolveFilePath(filePath);
        end
    
    end
end

% Reads a .coll file and returns parsed rows ready for loadScene.
function [collData, errMsg] = parseCollectionFile(collFullPath)

    % Fills defaults for color/view/offset/transparency/title
    % collData is {absPath, color, view, offsetVec(1x3), transparencyVal, title}
    collData = {}; errMsg   = "";

    if nargin < 1 || ~ischar(collFullPath) && ~isstring(collFullPath)
        errMsg = "No .coll file path provided.";
        return;
    end

    collFullPath = char(collFullPath);
    if ~exist(collFullPath, 'file')
        errMsg = "Unable to open the collection file: " + string(collFullPath);
        return;
    end

    fid = fopen(collFullPath, 'r');
    if fid == -1
        errMsg = "Unable to open the collection file: " + string(collFullPath);
        return;
    end

    cleaner = onCleanup(@() fclose(fid));
    validViews = {'cylinders','graph'};

    lineNo = 0;
    while ~feof(fid)
        raw = fgetl(fid);
        lineNo = lineNo + 1;

        if ~ischar(raw) || all(isspace(raw))
            continue; % skip empty lines
        end

        % Extract tokens
        paths  = regexp(raw, 'filename=''?([^,''"]+)''?', 'tokens');
        colors = regexp(raw, 'color=([^, ]+)', 'tokens');
        views  = regexp(raw, 'view=([^, ]+)',  'tokens');
        offsets = regexp(raw, 'offset=\(\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*\)', 'tokens');
        titleMatch = regexp(raw, 'title=''([^'']*)''', 'tokens');

        if isempty(paths)
            errMsg = compose("Invalid line %d in %s. Expected:\nfilename=<path>,color=<name>,view=<cylinders/graph>,offset=(x,y,z),transparency=0.2", ...
                              lineNo, collFullPath);
            collData = {};
            return;
        end

        fileToken = strtrim(paths{1}{1});

        % Defaults
        viewVal  = 'graph';
        if ~isempty(views) && any(strcmpi(views{1}{1}, validViews))
            viewVal = lower(views{1}{1});
        end

        if isempty(colors)
            colorVal = 'black';
        else
            colorVal = colors{1}{1};
        end
        colorVal = validateColor(colorVal);

        offsetVec = [0 0 0];
        if ~isempty(offsets)
            nums = str2double(offsets{1});
            if numel(nums) == 3 && all(isfinite(nums))
                offsetVec = nums(:).';
            end
        end

        % Transparency only applies to STL entries
        transparencyVal = 1;
        if contains(lower(fileToken), '.stl')
            tkn = regexp(raw, 'transparency=([0-1]?\.?\d+)', 'tokens');
            if ~isempty(tkn)
                val = str2double(tkn{1}{1});
                if isfinite(val) && val >= 0 && val <= 1
                    transparencyVal = val;
                end
            end
        end

        if ~isempty(titleMatch)
            titleVal = strtrim(titleMatch{1}{1});
        else
            [~, nm, ex] = fileparts(fileToken);
            titleVal = [nm, ex];
        end

        % Resolve path to absolute
        [absPath, found] = resolveFilePath(fileToken);
        if ~found
            errMsg = compose("File not found (line %d): %s", lineNo, string(fileToken));
            collData = {};
            return;
        end

        collData(end+1, :) = {absPath, colorVal, viewVal, offsetVec, transparencyVal, titleVal};
    end
end

function colorRGB = validateColor(colorName)
    colorName = lower(colorName);
    validColors = {'red', 'blue', 'green', 'cyan', 'magenta', 'yellow', 'black', 'white'};
    if ismember(colorName, validColors)
        color = colorName;
    else
        color = 'black';
    end
    colorRGB = validatecolor(color);
end


% Resolve absolute/relative file path (upto 5 levels below
function [absPath, found] = resolveFilePath(inputPath)
    absPath = ""; found = false;

    if ~(ischar(inputPath) || isstring(inputPath))
        return;
    end

    inputPath = char(inputPath);
    [inDir, inName, inExt] = fileparts(inputPath);
    target = [inName inExt];

    % 1) Absolute path: verify and return only if it exists
    if isAbsolutePath(inputPath)
        if exist(inputPath, 'file') == 2
            absPath = string(canonicalPath(inputPath));
            found = true;
        end
        return;
    end

    % 2) Relative with folder component: search within that folder (all depths)
    if ~isempty(inDir)
        baseDir = fullfile(pwd, inDir);
        if isfolder(baseDir) && ~isempty(target)
            hits = dir(fullfile(baseDir, '**', target));
            if ~isempty(hits) && ~hits(1).isdir
                absPath = string(fullfile(hits(1).folder, hits(1).name));
                found = true;
            end
        end
        return;
    end

    % 3) Bare filename: search all levels under pwd
    if ~isempty(target)
        hits = dir(fullfile(pwd, '**', target));
        if ~isempty(hits) && ~hits(1).isdir
            absPath = string(fullfile(hits(1).folder, hits(1).name));
            found = true;
        end
    end
end

function tf = isAbsolutePath(p)
% Windows: drive-rooted "C:\..." or UNC "\\server\share\..." --- POSIX: "/"-rooted
    if ispc
        tf = ~isempty(regexp(p, '^[A-Za-z]:[\\/]', 'once')) || startsWith(p, '\\');
    else
        tf = startsWith(p, filesep);
    end
end

function canon = canonicalPath(p)
% Normalize using dir so we return a canonical absolute path
    info = dir(p);
    if ~isempty(info)
        canon = fullfile(info(1).folder, info(1).name);
    else
        canon = p;
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
