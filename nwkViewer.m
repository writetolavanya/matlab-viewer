function nwkViewer()

   clear all; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure, axes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fig = uifigure('Name', 'Properties Window', 'Position', [50 30 350 820]);

   axesFig = figure('Name', 'LPPD Network Viewer', ...
       'Position', [400 30 900 780], 'Color', [1 1 1], 'NumberTitle', 'off');
   ax = axes(axesFig, 'Units','normalized',...
       "Position", [0 0 1 1]);
   axis 'off';

   % Set the CloseRequestFcn of both windows to close both figures
   fig.CloseRequestFcn = @closeBothFig;
   axesFig.CloseRequestFcn = @closeBothFig;

%%%%%%%%%%%%%%%%%%%% Global variable initialisations %%%%%%%%%%%%%%%%%%%%%%    

   global activeNwk activeG activeHandle activeIdx;

   global largeNwk;

   global tableGrpBoxes grpTitles;
   global applyBtn resetBtn renameBtn;

   global nodeColor preColor;

   global initialXLimits initialYLimits initialZLimits;
   global selectedFaces;

   initialXLimits = [0 5];
   initialYLimits = [0 5];
   initialZLimits = [0 5];

   largeNwk = 1000;
   G = graph([], []);
   faceProp = [];

   nodeColor = [0.2 0.2 0.2];
   preColor = [
    1.0, 0.0, 0.0;  % Red
    0.0, 0.0, 1.0;  % Blue
    0.0, 1.0, 0.0;  % Green
    0.0, 1.0, 1.0;  % Cyan
    1.0, 0.0, 1.0;  % Magenta
    0.5, 0.0, 1.0;  % Violet
    0.3, 0.3, 0.3;  % Dark Grey
    0.0, 0.5, 0.0;  % Dark Green
    1.0, 0.5, 0.0;  % Orange
    0.5, 0.0, 0.0;  % Maroon
    ];
   
   numColors = size(preColor, 1);

   set(ax, 'xtick', [],'xticklabel', [], 'ytick', [],'yticklabel', [], 'ztick', [], 'zticklabel', []);
   initialXLim = [-1 1];
   initialYLim = [-1 1];
   ax.XLim = initialXLim;
   ax.YLim = initialYLim;
   ax.ZLim = [-1, 1];

   % For shortest path pt storage
   twoPts4Paths = [];
   twoPts4MultiSelect = [];
   multiSelectFaceIdx = [];


%%%%%%%%%%%%%%%%%%%%%%%%%%%% UI options and tooltips %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

   % Create a uicontrol listbox (dropdown menu)
   fileDropdown = uicontrol(axesFig, 'Style', 'popupmenu', 'String', ' ', ...
                         'Position', [0 745 900 30], 'Callback', @changeActiveFile);

   %Create tabbed panels (if parent is figure for tabbed group, position should be in percentages)
   tabgp = uitabgroup(fig,"Position", [20 40 300 700], "SelectionChangedFcn", @tabChangeCb);
   viewTab = uitab(tabgp,"Title", "View", "BackgroundColor", [0.8 0.8 0.8]);
   pathTab = uitab(tabgp,"Title", "Path", "BackgroundColor", [0.8 0.8 0.8]);
   tab3 = uitab(tabgp, "Title","Transform/Scale", "BackgroundColor",[0.8 0.8 0.8]);

   %Create load, clear, save buttons in Properties window
   loadButton = uibutton(fig, 'push', 'Text', 'Load', 'Position', [22, 780, 50, 25], ...
        'ButtonPushedFcn', @loadButtonCb);

   clearButton = uibutton(fig, 'push', 'Text', 'Clear', 'Position', [22, 750, 50, 25], ...
        'ButtonPushedFcn', @clearPlotCb);

   saveButton = uibutton(fig, 'push', 'Text', 'Save Coll', 'Position', [80, 780, 80, 25], ...
       'ButtonPushedFcn', @saveColl);

   saveNwk = uibutton(fig, 'push', 'Text', 'Save Nwk', 'Position', [80, 750, 80, 25], ...
       'ButtonPushedFcn', @saveNwkCb);

   snapShotBtn = uibutton(fig, 'push', 'Text', 'Snapshot', 'Position', [170 750 80 25],...
       'ButtonPushedFcn', @snapshotCb);


   %Create first group of checkboes in View tab
   labelsOn = uicheckbox(viewTab, "Text", "labelsOn", ...
       "Position",[22 650 70 22], 'ValueChangedFcn', @labelsOnCb);

   directionsOn = uicheckbox(viewTab, "Text", "directionsOn", ...
       "Position",[22 630 100 22], 'ValueChangedFcn', @directionsOnCb);

   ptSelect = uicheckbox(viewTab, "Text", "PtSelect", ...
       "Position",[22 610 70 22], "ValueChangedFcn", @ptSelectCb);

   toggleCylindersView = uicheckbox(viewTab, "Text", "toggleCylindersView",...
       "Position",[140 650 130 22], "ValueChangedFcn", {@togglePlotCb, [], []});

   boundingBoxOn = uicheckbox(viewTab, "Text", "BoundingBoxOn",...
       "Position",[140 630 110 22], "ValueChangedFcn", @boundingBoxCb);
   
   faceSelect = uicheckbox(viewTab, "Text", "faceSelect",...
       "Position",[140 610 80 22], "ValueChangedFcn", @faceSelectCb);

   togglePtCloudView = uicheckbox(viewTab, "Text", "togglePtCloudView", ...
       "Position", [140 590 130 22], "ValueChangedFcn", @togglePtCloudCb);

   % %Create transparency textbox in View tab
   % transparencyLabel = uilabel(viewTab, 'Text', 'Transparency',...
   %     'Position', [80, 575, 80, 22]);
   % transparency = uieditfield(viewTab,"numeric",...
   %     "Value", [],...
   %     "Limits",[-5 10],...
   %     "AllowEmpty","on",...
   %     "Position", [165 575 100 22]);

   %Create a button group for Endpoints and Endfaces in View tab
   endpointsGrp = uibuttongroup(viewTab, "Title", "Show EndPoints",...
       "TitlePosition","lefttop", "Position", [20, 508, 260, 80],...
       "BackgroundColor",[0.8 0.8 0.8], "SelectionChangedFcn", @updateEndPoints);

   endfacesGrp = uibuttongroup(viewTab, "Title", "Show EndFaces",...
       "TitlePosition","lefttop", "Position", [20, 423, 260, 80],...
       "BackgroundColor",[0.8 0.8 0.8], "SelectionChangedFcn", @updateEndFaces);

   %Create radio buttons in Endpoints and Endfaces in Buttongroup
   ptNoneRb1 = uiradiobutton(endpointsGrp, "Text", "None", "Position", [10 30 80 20], 'Value', true);
   ptAllRb2 = uiradiobutton(endpointsGrp, 'Text', 'All EndPoints', 'Position', [10 5 100 20]);
   ptInletRb3 = uiradiobutton(endpointsGrp, 'Text', 'InletPoints', 'Position', [130 30 80 20]);
   ptOutletRb4 = uiradiobutton(endpointsGrp, 'Text', 'OutletPoints', 'Position', [130 5 100 20]);

   facesRb1 = uiradiobutton(endfacesGrp, "Text", "None", "Position", [10 30 80 20]);
   facesRb2 = uiradiobutton(endfacesGrp, 'Text', 'All EndFaces', 'Position', [10 5 100 20]);
   facesRb3 = uiradiobutton(endfacesGrp, 'Text', 'InletFaces', 'Position', [130 30 80 20]);
   facesRb4 = uiradiobutton(endfacesGrp, 'Text', 'OutletFaces', 'Position', [130 5 100 20]);

   %Create panel for selection and edits in View tab
   editGrp = uipanel(viewTab, "Position", [20, 248, 260, 170], "BackgroundColor",[0.8 0.8 0.8]);

   selectionGrp = uibuttongroup(viewTab, "Title", "Selection",...
       "TitlePosition","lefttop", "Position", [28, 363, 240, 50],...
       "BackgroundColor",[0.8 0.8 0.8], "SelectionChangedFcn", @updateSelections);

   %Create radio buttons in selection Group Buttongroup
   selectionRb1 = uiradiobutton(selectionGrp, "Text", "Both", 'Value', true, "Position", [10 5 50 20]);
   selectionRb2 = uiradiobutton(selectionGrp, 'Text', 'Selections', 'Position', [65 5 80 20]);
   selectionRb3 = uiradiobutton(selectionGrp, 'Text', '~Selections', 'Position', [150 5 80 20]);
   
   %Create face edit label and edit box
   faceEditLabel = uilabel(viewTab, 'Text', 'faceEdit', 'Position', [28 345 50 15]);
   
   faceEditBox = uitextarea(viewTab, "Value", '', ...
       "Position", [80 325 190 35], 'Editable', 'on', 'HorizontalAlignment', 'left', 'WordWrap', 'on');

   faceZoomBtn = uibutton(viewTab, 'push', 'Text', 'Zoom', 'Position', [28 325 50 15],...
       'FontSize', 8, 'ButtonPushedFcn', @faceZoomCb);

   %Create point edit label and edit box
   ptEditLabel = uilabel(viewTab, 'Text', 'pointEdit', 'Position', [28 305 50 15]);
   
   ptEditBox = uitextarea(viewTab, "Value", '', "Position", [80 285 190 35], ...
       'Editable', 'on', 'HorizontalAlignment', 'left', 'WordWrap', 'on');

   ptZoomBtn = uibutton(viewTab, 'push', 'Text', 'Zoom', 'Position', [28 285 50 15],...
       'FontSize', 8, 'ButtonPushedFcn', @ptZoomCb);
    
    faceEditBox.Tooltip = sprintf(['Allowed formats:\n' ...
        '- Entries separated by commas.\n' ...
        '- Entries can be:\n' ...
        '  1. Single integers (e.g., ''12,23,18'' for face IDs 12, 23, 18).\n' ...
        '  2. Ranges (e.g., ''18:22'' for face IDs 18, 19, 20, 21, 22).\n' ...
        '  3. Logical conditions:\n' ...
        '        - Symbols: d (diameter), l (face length), f (face ID), g (group ID) ' ...
        '           p1 (inlet point), p2 (outlet point)\n' ...
        '         - Operators: >, <, =\n' ...
        '         - Combine conditions with ''&''.\n' ...
        '         - Example usage: ''d>2&l<10,f>10&f<15,g=13,p1=100''\n' ...
        '              - ''d>2&l<10'' (Faces with diameter > 2 and face length < 10)\n' ...
        '              - ''f>10&f<15'' (Faces with face ID equal to 11,12,13,14)\n' ...
        '              - ''g=13'' (Faces with group ID equal to 13)\n' ...
        '              - ''p1=100''(Faces that have inlet point as 100)\n']);


   ptEditBox.Tooltip = sprintf(['Allowed formats:\n' ...
        '- Entries separated by commas.\n' ...
        '- Entries can be:\n' ...
        '  1. Single integers (e.g., ''12,23,18'' for point IDs 12, 23, 18)\n' ...
        '  2. Ranges (e.g., ''18:21'' for point IDs 18, 19, 20, 21)\n' ...
        '  3. Logical conditions:\n' ...
        '        - Symbols: DGi (Indegree of a point), DGo (Outdegree of a point), ' ...
        '           p (point ID), X (X-cordinate of a point) ' ...
        '           Y (Y-cordinate of a point), Z (Z-cordinate of a point)\n' ...
        '         - Operators: >, <, =\n' ...
        '         - Combine conditions with ''&''.\n' ...
        '         - Example usage: ''X<100&X>20,DGi=1&DGo=2,p>7''\n' ...
        '              - ''X<100&X>20'' (Points with x coordinate between 20 and 100)\n' ...
        '              - ''DGi=1&DGo=2'' (Points with 1 indegree and 2 outdegree, bifurcation points)\n' ...
        '              - ''p>7'' (Points with point IDs from 8 to total number of points(np))\n']);

   %Create the Display and Reset button
   displayButton = uibutton(viewTab, 'Text', 'Display',...
       'Position', [30 257 60 20], 'FontSize', 10, 'ButtonPushedFcn', @updateSelections);

   resetButton = uibutton(viewTab, 'Text', 'Reset',...
       'Position', [100 257 60 20], 'FontSize', 10, 'ButtonPushedFcn', @resetSelections);

   resetButton.Tooltip = sprintf(['Clears text in the edit boxes, resets the view to `Both`\n' ...
       'and redraws the graph using group colors.']);

   editButton = uibutton(viewTab, 'Text', 'Edit',...
       'Position', [170 257 60 20], 'FontSize', 10, 'ButtonPushedFcn', @editSelections);

   editButton.Tooltip = sprintf(['Edit the point coordiantes of selected point indices, and\n' ...
       'Edit the group id, diameter and endpoints of selected face indices']);

   % Create a toggle button that switches between 'AND' and 'OR'
   andOrBtn = uibutton(viewTab, 'Text', 'AND', 'FontSize', 10, 'Position', [235 257 40 20], ...
      'ButtonPushedFcn', @andOrCb);

   andOrBtn.Tooltip = sprintf(['Gives faces, points that are a Union\n' ...
       'of faceEdit and ptEdit conditions']);

   %Create a tabbed panel with color selections
   colorTab = uitabgroup(viewTab, 'Position', [20, 28, 260, 215], 'SelectionChangedFcn', {@onTabSelection});
   faceGrp = uitab(colorTab, 'Title', 'FaceGroup', 'BackgroundColor', [0.8, 0.8, 0.8], 'Scrollable', 'on');
   propertiesTab = uitab(colorTab, 'Title', 'Properties', 'BackgroundColor', [0.8, 0.8, 0.8], 'Scrollable', 'on');

   colorGrp = uibuttongroup(propertiesTab, 'Title', 'faceProp', ...
        'TitlePosition', 'lefttop', 'Position', [28, 60, 80, 150], ...
        'BackgroundColor', [0.8 0.8 0.8], 'SelectionChangedFcn', @updateFaceProp);

   % Table to store all the loaded objects
   rendererTable = table('Size', [0, 7], ...
                   'VariableTypes', {'string', 'string', 'cell', 'cell', 'cell', 'cell', 'cell'}, ...
                   'VariableNames', {'fileName', 'type', 'nwkObj', 'plotHandle', 'graphObj', 'boxHandle', 'grpColors'});

   viewTable = table('Size', [0, 4], ...
                    'VariableTypes', {'string', 'string', 'cell', 'cell'}, ...
                    'VariableNames', {'fileName', 'type', 'nwkObj', 'patchObj'});

   warning('off', 'all');

   %%%%%%%%%%%%%%%%% UI options in Path tab %%%%%%%%%%%%%%%%%%

    shortestPathSelect = uicheckbox(pathTab, "Text", "shortestPathSelect",...
       "Position",[18, 600, 255, 60], "ValueChangedFcn", @shortestPathCb);

    connectedComp = uicheckbox(pathTab, "Text", "connectedComponents", ...
       "Position",[18, 530, 255, 60], "ValueChangedFcn", @connectedCompCb);

    multiSelect =  uicheckbox(pathTab, "Text", "multiSelectFaces",...
       "Position", [18, 480, 120, 30], "ValueChangedFcn", @multiSelectCb);
    
    deleteFacesBtn = uibutton(pathTab, "Text", sprintf('Delete\nFaces'), ...
        "Position", [130, 480, 50, 30], 'FontSize', 9,  "ButtonPushedFcn", @deleteFacesCb);
    
    assignGroupBtn = uibutton(pathTab, "Text", sprintf('Assign\nGroup'), ...
        "Position", [185, 480, 50, 30], 'FontSize', 9,  "ButtonPushedFcn", @assignGroupCb);

    groupIdBox = uicontrol(pathTab, 'Style', 'edit', 'Position', [240, 485, 40, 22]);

    uilabel(pathTab, 'Text', 'Indexes of Selected Faces:', 'FontAngle', 'italic', 'FontColor', [0.3 0.3 0.3], ...
        'FontSize', 8, 'Position', [28 460 150 15]);
    
    selectedFaces = uicontrol(pathTab, 'Style', 'edit', 'Max', 2, 'String', '', ...
        'Position', [20, 200, 270, 255], 'HorizontalAlignment', 'left');

   %%%%%%%%%%%%%%%%%%%%%%%% Annotation %%%%%%%%%%%%%%%%%%%%%%%%

   % Add annotation with author and supervisor
   annotation(fig, 'textbox', [0.3, 0.001, 0.65, 0.04], 'String', ...
        {'Authored by Lavanya Vaddavalli', 'Directed by Andreas Linninger'}, ...
        'FontSize', 8, 'FontAngle', 'italic', 'Color', [0.3 0.3 0.3], ...
        'EdgeColor', 'none', 'HorizontalAlignment', 'right');

%%%%%%%%%%%%%%%%%%%%%%%% UI Callback functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   function togglePtCloudCb(~, ~)
       fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

       if togglePtCloudView.Value

            if ~isempty(rendererTable.plotHandle{activeIdx})
                delete(rendererTable.plotHandle{activeIdx});
            end

            % take the maximum radius among all connected faces.
            indices = [activeNwk.faceMx(:,2); activeNwk.faceMx(:,3)];
            radius = [activeNwk.dia / 2 ; activeNwk.dia / 2];
            activeNwk.ptRad = accumarray(indices, radius, [activeNwk.np, 1], @max, 0);
            
            % take the majority of group id among all connected faces
            group_ids = [activeNwk.faceMx(:,1); activeNwk.faceMx(:,1)];
            activeNwk.ptGroup = accumarray(indices, group_ids, [activeNwk.np, 1], @mode, 0);
            ptColorMapping = cell2mat(arrayfun(@(g) rendererTable.grpColors{activeIdx}{g}, activeNwk.ptGroup, 'UniformOutput', false));
            
            pcloud = pointCloud(activeNwk.ptCoordMx, 'Intensity', activeNwk.ptRad, 'Color', ptColorMapping);
            activeHandle = pcshow(pcloud, 'Parent', ax, 'AxesVisibility', 'off', 'BackgroundColor', [1 1 1]);
            axis 'off';

            rendererTable.plotHandle{activeIdx} = activeHandle;
            activeHandle.UserData(1).type = 'ptCloud';

       elseif strcmp(activeHandle.UserData(1).type, 'ptCloud') && ~togglePtCloudView.Value
           if  ~isempty(ptEditBox.Value{1}) || ~isempty(faceEditBox.Value{1})
                  updateSelections();
           else
               if ~isempty(colorGrp.Children)
                   updateFaceProp();
               else
                   faceGrpEditCb();
                   colorbar("off");
               end
           end
       end

       fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
   end    
    
   function togglePlotCb(~, ~, facesList, faceProp, collColor)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        if toggleCylindersView.Value

            if isempty(facesList)
                if ~isempty(tableGrpBoxes) 
                    groupIds = findCheckedGrpIds();
                    facesList = find(ismember(activeNwk.faceMx(:, 1), groupIds));
                
                    %elseif ~isempty(activeHandle.UserData(1).selections) 
                    %selections will have hanging points too, then?
                else
                    facesList = (1:activeNwk.nf)';
                end
            end

            if ~isempty(rendererTable.plotHandle{activeIdx})
                delete(rendererTable.plotHandle{activeIdx});
            end

            color = [];
            colorbarFlag = false;
            if nargin > 4 && ~isempty(collColor)
                color = collColor;
            elseif ~isempty(rendererTable.grpColors{activeIdx})
                firstColor = rendererTable.grpColors{activeIdx}.values{1};
                for i = 2:length(rendererTable.grpColors{activeIdx}.keys)
                    if ~isequal(rendererTable.grpColors{activeIdx}.values{i}, firstColor)
                        color = jet(256);
                        colorbarFlag = true;
                        break;
                    end
                end
                if isempty(color)
                    color = firstColor;
                end
            else
                color = jet(256);
                colorbarFlag = true;
            end

            if isempty(faceProp)
                if ~isempty(colorGrp.Children)
                    faceProp = extractFaceProp();
                else
                    faceProp = activeNwk.dia;
                end
            end

            hold(ax, 'on');
            [~, activeHandle] = RenderNwkTV(activeNwk, facesList, faceProp, [], [], [], color);
            if colorbarFlag
                addColorbar(faceProp(facesList));
            end
            hold(ax, 'off');

            rendererTable.plotHandle{activeIdx} = activeHandle;

            activeHandle.UserData(1).type = 'cylinders';

            labelsOn.Value = false;
            directionsOn.Value = false;

            resetOnRedraw();

        elseif strcmp(activeHandle.UserData(1).type, 'cylinders') && ~toggleCylindersView.Value

            if  ~isempty(ptEditBox.Value{1}) || ~isempty(faceEditBox.Value{1})
                   updateSelections();
            else
                if ~isempty(colorGrp.Children)
                    updateFaceProp();
                else
                    faceGrpEditCb();
                    colorbar("off");
                end

            end
        end
        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';

    end

    % Callback for file drop down menu
    function changeActiveFile(~, ~)

        if isequal(fileDropdown.Value, 1) && isequal(fileDropdown.String, ' ')
            return;
        end
    
        activeIdx = fileDropdown.Value;
        activeNwk = rendererTable.nwkObj{activeIdx};
        activeG = rendererTable.graphObj{activeIdx};
        activeHandle = rendererTable.plotHandle{activeIdx};

        % Restore groups and selections 
        initGroupBox();

        if isfield(activeHandle.UserData, 'selections') && ~isempty(activeHandle.UserData(1).selections)
            ptEditBox.Value = activeHandle.UserData(1).selections{1};
            faceEditBox.Value = activeHandle.UserData(1).selections{2};
            if activeHandle.UserData(1).selections{3} == 1
                selectionRb1.Value = true;
            elseif activeHandle.UserData(1).selections{3} == 2
                selectionRb2.Value = true;
            else
                selectionRb3.Value = true;
            end    
        else
            selectionRb2.Value = false;
            selectionRb1.Value = true;
            selectionRb3.Value = false;
    
            faceEditBox.Value = '';
            ptEditBox.Value = '';
            
        end

        reApplyUIOptions();
        initGroupBox();
        onTabSelection();

        updateEndPoints();
        updateEndFaces();

    end

    function loadButtonCb(~, ~)

         [file, path] = uigetfile('*.fMx;*.coll;*.stl;*.msh;*.nwk;*.nwkx', 'Select a file to load');
         if isequal(file, 0) || isequal(path, 0)
              disp('File selection canceled');
              return
         end
         [~, ~, ext] = fileparts(fullfile(path, file));

         fig.Pointer = 'watch'; axesFig.Pointer = 'watch';
         tic;
        
         if strcmp(ext, '.coll')
            fid = fopen(fullfile(path, file), 'r');
            if fid == -1
                disp('Unable to open the collection file.');
                return
            end

            validViews = {'cylinders', 'graph'};
            collData = {};
    
             while ~feof(fid)
                line = fgetl(fid);
                offsetVec = [0, 0, 0]; transparencyVal = 1; 
                
                paths = regexp(line, 'filename=''?([^,''"]+)''?', 'tokens');
                colors = regexp(line, 'color=([^, ]+)', 'tokens');
                views = regexp(line, 'view=([^, ]+)', 'tokens');
                offsets = regexp(line, 'offset=\(\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*\)', 'tokens'); % allows spaces and  eg: -92.18 format
                
                if isempty(paths)
                    disp('Invalid collection file. Format should be: ');
                    disp('filename=<absolute-path-to-filename>,color=<color-name>,view=<cylinders/graph>,offset=(100,0,0),transparency=0.2');
                    return
                else
                    if isempty(views) || ~ismember(views{1}{1}, validViews)
                       views{1}{1} = 'graph';
                    end
                    if isempty(colors)
                        colors{1}{1} = 'black';
                    end
                    
                    % Parse offset string to numeric array
                    offsetVec = [0, 0, 0];
                    if ~isempty(offsets)
                        offsetVec = str2double(offsets{1});
                    end

                    % Parse transparency value and it should be in [0,1]
                    transparencyVal = 1;
                    if contains(lower(paths{1}{1}), '.stl')
                        transparency = regexp(line, 'transparency=([0-1]?\.?\d+)', 'tokens');
                        if ~isempty(transparency)
                            val = str2double(transparency{1}{1});
                            if val >= 0 && val <= 1
                                transparencyVal = val;
                            else
                                disp('Invalid transparency value, so defaulting to 1. Value should be between 0 and 1.');
                            end
                        end
                    end

                    colors{1}{1} = validateColor(colors{1}{1});
                    collData(end+1, :) = {paths{1}{1}, colors{1}{1}, views{1}{1}, offsetVec, transparencyVal};
                end
            end

            fclose(fid);
            
            for i = 1:size(collData, 1)
                collFilePath = collData{i, 1};
                loadScene(collFilePath, collData{i, 3}, collData{i, 2}, collData{i, 4}, collData{i, 5});
                fprintf("Loaded nwk : %s\n", collFilePath);
            end

         else
            
             loadScene(fullfile(path, file), 'graph', [0,0,0], 1);
             initGroupBox();

         end

         % Reset point and face highlights' UI options
         ptNoneRb1.Value = true;
         facesRb1.Value = true;
 
         selectionRb1.Value = true;
         faceEditBox.Value = '';
         ptEditBox.Value = '';
          
         fileDropdown.String = rendererTable.fileName(:);
         fileDropdown.Value = activeIdx;

         loadTime = toc;
         fprintf("Load time for nwk : %.2f seconds\n", loadTime);
         fig.Pointer = 'arrow';  axesFig.Pointer = 'arrow';
       
    end

    function loadScene(filePath, view, offsetVec, transparency, collColor)
         [path, name, ext] = fileparts(filePath);

         if strcmp(ext, '.nwkx'); ext = '.fMx'; end

         if strcmp(ext, '.fMx')
             activeNwk = nwkHelp.load(fullfile(path, name));
             activeNwk.ptCoordMx = activeNwk.ptCoordMx + offsetVec; % add offset from coll, or default is [0,0,0]

             lsFile = [fullfile(path, name), '.ls'];
             if exist(lsFile, 'file') == 2
                 activeNwk.ls = load(lsFile);
             end

             activeIdx = size(rendererTable, 1) + 1;
             rendererTable(activeIdx, 1:3) = {filePath, ext, {activeNwk}};
            
             if activeNwk.nf > largeNwk || activeNwk.np > largeNwk
                  grpIds = selectLoadGrps();
                  facesList = find(ismember(activeNwk.faceMx(:, 1), grpIds));

                  if strcmp(view, 'graph')
                      toggleCylindersView.Value = false;
                      plotSubsetFacesPts(facesList, []);
                  else
                      toggleCylindersView.Value = true;
                      togglePlotCb([], [], facesList, activeNwk.dia, collColor);
                  end
                  activeHandle.UserData(1).groups = grpIds;
             else
                 if strcmp(view, 'graph')
                     toggleCylindersView.Value = false;
                     plotGraph();
                 else
                     toggleCylindersView.Value = true;
                     togglePlotCb([], [], (1:activeNwk.nf)', activeNwk.dia, collColor);
                 end
             end

             expandAxesLimits(ax, activeNwk);
             createPngForIco(filePath);
             if nargin > 4 && ~isempty(collColor)
                 initGroupBox(collColor);
             else
                 initGroupBox();
             end

             onTabSelection(); % Add radio buttons for new object

         elseif strcmp(ext, '.stl')

             stlNwk = nwkConverter.stl2faceMx3(filePath);
             idx = size(viewTable, 1) + 1;
             stlNwk.ptCoordMx = stlNwk.ptCoordMx + offsetVec;  % add offset from coll, or default is [0,0,0]
             viewTable(idx, 1:3) = {filePath, ext, {stlNwk}};
             plotStl(stlNwk, transparency);
             expandAxesLimits(ax, stlNwk);

         elseif strcmp(ext, '.msh') || strcmp(ext, '.nwk')

             mshNwk = nwkConverter.msh2nwk(filePath);
             idx = size(viewTable, 1) + 1;
             mshNwk.ptCoordMx = mshNwk.ptCoordMx + offsetVec; % add offset from coll, or default is [0,0,0]
             viewTable(idx, 1:3) = {filePath, ext, {mshNwk}};
             plotMsh(mshNwk);
             expandAxesLimits(ax, mshNwk);
         end

    end

    function saveColl(~, ~)

        [file, path] = uiputfile('*.coll', 'Save Scene Collection As');
        if isequal(file, 0) || isequal(path, 0)
            disp('Saving canceled.');
            return;
        end

        fid = fopen(fullfile(path, file), 'w');
        if fid == -1
            error('Unable to open or create the file.');
        end

        for i = 1:size(rendererTable, 1) 
            fprintf(fid, 'filename=%s', rendererTable.fileName{i});
            
            colorName = getObjColorName(rendererTable.grpColors{i});
            fprintf(fid, ',color=%s', colorName);

            view = rendererTable.plotHandle{i}.UserData(1).type;
            if contains(view, 'graph')
                fprintf(fid, ',view=%s\n', view);
            else
                fprintf(fid, ',view=%s\n', 'cylinders');
            end
        end

        for i = 1:size(viewTable, 1)
            fprintf(fid, 'filename=%s\n', viewTable.fileName{i});
        end

        fclose(fid);
        disp(['Scene collection saved to: ', fullfile(path, file)]);

    end


    function saveNwkCb(~, ~)

        if isempty(activeNwk)
            disp('No network loaded to save');
            return;
        end

        [file, path] = uiputfile('*', 'Save Active Network As');
        if isequal(file, 0) || isequal(path, 0)
            disp('Saving canceled.');
            return;
        end

        [~, baseName, ~] = fileparts(file);
        pFileName = [baseName, '.pMx']; fFileName = [baseName, '.fMx']; dFileName = [baseName, '.dia'];
  
        fileID = fopen(fullfile(path, pFileName), 'w');
        fprintf(fileID, '%.15f %.15f %.15f\n', [activeG.Nodes.X, activeG.Nodes.Y, activeG.Nodes.Z]');
        fclose(fileID);

        fileID = fopen(fullfile(path, fFileName), 'w');
        fprintf(fileID, '%d %d %d %d %d\n', [activeNwk.faceMx(activeG.Edges.Weight(:), 1), activeG.Edges.EndNodes(:, 1), ...
            activeG.Edges.EndNodes(:, 2), zeros(height(activeG.Edges), 1), zeros(height(activeG.Edges), 1)]');
        fclose(fileID);

        saveDia = activeNwk.dia(activeG.Edges.Weight(:));
        fileID = fopen(fullfile(path, dFileName), 'w');
        fprintf(fileID, '%.15f\n', saveDia);
        fclose(fileID);

        disp(['Active Network saved to: ', fullfile(path, file)]);

    end

    function initGroupBox(collColor)

        delGrpCheckboxes();

        if isempty(activeNwk) || activeNwk.nf <= 0 % Point cloud 
            return;
        end   

        uniqueGroupIDs = unique(activeNwk.faceMx(:, 1));
        numGrpIds = numel(uniqueGroupIDs);
        tableGrpBoxes = table('Size', [numGrpIds, 3], ...
                   'VariableTypes', {'cell', 'cell', 'cell'}, ...
                   'VariableNames', {'grpBoxHandles', 'colorPickers', 'numFaces'});
        grpTitles = table('Size', [numGrpIds, 1], ...
                   'VariableTypes', {'cell'}, ...
                   'VariableNames', {'title'});
        
        len = 20 * numGrpIds + 5;
        if len < 230
            len = 210;
        end
      
        scroll(faceGrp, 'top');

        colorsExist = false;
        if nargin > 0 && ~isempty(collColor)
             grpColor = configureDictionary("double", "cell");
        elseif isempty(rendererTable.grpColors{activeIdx})
             grpColor = configureDictionary("double", "cell");
             collColor = '';
        else
             colorsExist = true;
        end

        if isfield(activeHandle.UserData, 'groups') && ~isempty(activeHandle.UserData(1).groups)
            groupIds = activeHandle.UserData(1).groups;
        else
            groupIds = uniqueGroupIDs;
        end

        % Titles
        grpTitles.title{1} = uilabel(faceGrp, 'Text', 'Group ID', 'FontWeight', 'bold', 'FontSize', 10, ...
            'HorizontalAlignment', 'left', 'Position', [20, len + 15, 60, 15]);
        grpTitles.title{2} = uilabel(faceGrp, 'Text', 'Color', 'FontWeight', 'bold', 'FontSize', 10, ...
            'HorizontalAlignment', 'left', 'Position', [90, len + 15, 30, 15]);
        grpTitles.title{3} = uilabel(faceGrp, 'Text', 'Faces', 'FontWeight', 'bold', 'FontSize', 10, ...
            'HorizontalAlignment', 'left', 'Position', [130, len + 15, 60, 15]);

        for i = 1:numGrpIds
            isChecked = ismember(uniqueGroupIDs(i), groupIds);

            grpChkBox = uicheckbox(faceGrp, 'Text', num2str(uniqueGroupIDs(i)), ...
               'Value', isChecked, 'Position', [20,  len - i * 20, 60, 20]);

            if colorsExist 
                if isKey(rendererTable.grpColors{activeIdx}, uniqueGroupIDs(i))
                    color = rendererTable.grpColors{activeIdx}{uniqueGroupIDs(i)};
                else  % When network's group ids are edited, useful when new grpid is added
                    colorIdx = mod(i-1, numColors) + 1;
                    rendererTable.grpColors{activeIdx}{uniqueGroupIDs(i)} = preColor(colorIdx, :);
                    color = rendererTable.grpColors{activeIdx}{uniqueGroupIDs(i)};
                end    
            else
                if isempty(collColor)
                    colorIdx = mod(i-1, numColors) + 1;
                    color = preColor(colorIdx, :);
                else
                    color = collColor;
                end
                grpColor(uniqueGroupIDs(i)) = {color};
            end
            
            colorBox = uicolorpicker(faceGrp, 'Value', color, ...
                'Position', [90,  len - i * 20, 30, 20]);

            numFaces = sum(ismember(activeNwk.faceMx(:, 1), uniqueGroupIDs(i)));        
            nfLabel = uilabel(faceGrp, 'Text', sprintf('(%d)', numFaces), 'FontSize', 8, ...
                'Position', [130, len - i * 20, 60, 20]);

            grpChkBox.UserData = i; % table index
            colorBox.UserData = uniqueGroupIDs(i); % group index            
            tableGrpBoxes{i, :} =  {grpChkBox, colorBox, nfLabel};
        end

        applyBtn = uibutton(faceGrp, 'Text', 'Apply', 'FontSize', 10, ...
            'Position', [200, 180, 50, 30], 'ButtonPushedFcn', @faceGrpEditCb);

        applyBtn.Tooltip = sprintf('Apply the group colors to the network');

        resetBtn = uibutton(faceGrp, 'Text', 'Reset', 'FontSize', 10, ...
            'Position', [200, 140, 50, 30], 'ButtonPushedFcn', @resetColors);

        resetBtn.Tooltip = sprintf(['Reset the colors for the groups\n' ...
            'and apply the group colors to the network']);

        renameBtn = uibutton(faceGrp, 'Text', 'Rename', 'FontSize', 10, ...
            'Position', [200, 100, 50, 30], 'ButtonPushedFcn', @renameGrps);

        renameBtn.Tooltip = sprintf(['Rename an old group id to new group id\n' ...
            'or change group id for few face indices']);

        if ~colorsExist
            rendererTable.grpColors{activeIdx} = grpColor;
            reColorGrps();
        else
            % remove stale group ids upon editing / renaming
            allGrpIds = rendererTable.grpColors{activeIdx}.keys;
            for i = 1:length(allGrpIds)
                if ~ismember(allGrpIds(i), uniqueGroupIDs)
                    rendererTable.grpColors{activeIdx}(allGrpIds(i)) = [];
                end
            end
    
        end

    end


    function clearPlotCb(~, ~)
        objNames = rendererTable.fileName;

        if ~isempty(viewTable)
            viewNames = viewTable.fileName;
            objNames = [objNames ; viewNames];
        end

        if isempty(objNames)
            disp('Clear operation cancelled. No object loaded onto the viewer.');
            return;
        end

        [selectedIdx, ok] = listdlg('ListString', objNames, 'SelectionMode', 'multiple',...
            'PromptString', 'Select an object to clear:', 'Name', 'Select Object', 'ListSize', [300, 100]);        
    
        if ok
            selectedIdx = sort(selectedIdx, 'descend');
            for i = 1:numel(selectedIdx)
                if ~isempty(viewTable) && selectedIdx(i) > size(rendererTable, 1)
                    idx = selectedIdx(i) - size(rendererTable, 1);
                    delete(viewTable.patchObj{idx});
                    viewTable(idx, :) = [];
                else
                    delete(rendererTable.plotHandle{selectedIdx(i)});
                    rendererTable(selectedIdx(i), :) = [];
        
                    fileDropdown.String = rendererTable.fileName(:);
        
                    if activeIdx == selectedIdx(i) % delete active obj
                        if size(rendererTable, 1) > 0
                            fileDropdown.Value = size(rendererTable, 1);
                            changeActiveFile();
                        else
                            fileDropdown.String = ' ';
                            delGrpCheckboxes();
                            if ~isempty(colorGrp.Children)
                                delete(colorGrp.Children);
                            end
                        end
                    elseif activeIdx > selectedIdx(i)
                        activeIdx = activeIdx - 1;
                        fileDropdown.Value = activeIdx;
                        activeNwk = rendererTable.nwkObj{activeIdx};
                        activeG = rendererTable.graphObj{activeIdx};
                        activeHandle = rendererTable.plotHandle{activeIdx};
                    end
                end
            end
        end
    end


    function plotGraph(~, ~)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        if directionsOn.Value && activeNwk.nf
            G = digraph(activeNwk.faceMx(:, 2), activeNwk.faceMx(:, 3), 1:activeNwk.nf);
            type = 'digraph';
        elseif activeNwk.nf 
            G = graph(activeNwk.faceMx(:, 2), activeNwk.faceMx(:, 3), 1:activeNwk.nf);
            type = 'graph';
        else % point cloud
            G = graph([], []);
            G = addnode(G, activeNwk.np);
            type = 'graph';
        end

        if ~isempty(rendererTable.plotHandle{activeIdx})
            delete(rendererTable.plotHandle{activeIdx});
        end

        G.Nodes = table(activeNwk.ptCoordMx(:, 1), activeNwk.ptCoordMx(:, 2), activeNwk.ptCoordMx(:, 3),...
           'VariableNames', {'X', 'Y', 'Z'});
        G.Nodes.Labels(:) = 1:activeNwk.np;

        hold(ax, "on");
        activeHandle = plot(G, 'XData', G.Nodes.X, 'YData', G.Nodes.Y, ...
            'ZData', G.Nodes.Z, 'NodeColor', nodeColor,...
            'EdgeColor', '[0 0 0.5]', 'NodeLabel', {}, 'MarkerSize', 2, 'LineWidth', 2, 'Parent', ax);
        hold(ax, "off");

        activeHandle.UserData = struct('type', '', 'selections', {}, 'groups', []);
        activeHandle.UserData(1).type = type;
        activeG = G;
        rendererTable(activeIdx, 4:5) = {{activeHandle}, {activeG}};

        if labelsOn.Value
            labelsOnCb();
        end

        resetOnRedraw();

        drawnow;

        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end

    function plotStl(stlNwk, transparency)
        
        hold(ax, "on");
        stlHandle = patch(ax, 'Faces', stlNwk.faceMx3(:, 2:4), 'Vertices', stlNwk.ptCoordMx, ...
            'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.75 0.75 0.75], 'FaceAlpha', transparency);
        hold(ax, "off");

        idx = size(viewTable, 1);
        viewTable(idx, 4) = {{stlHandle}};

    end  

    function plotMsh(mshNwk)
        
        hold(ax, "on");
        nFace = size(mshNwk.faceMx, 2) - 3;
        mshHandle = patch(ax, 'Faces', mshNwk.faceMx(:, 2:(2+nFace-1)), 'Vertices', mshNwk.ptCoordMx, ...
                'FaceColor', [0.4 0.4 0.4], 'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 4);
        hold(ax, "off");

        idx = size(viewTable, 1);
        viewTable(idx, 4) = {{mshHandle}};

    end  

    function expandAxesLimits(ax, Nwk)
        maxLims = max(Nwk.ptCoordMx);
        minLims = min(Nwk.ptCoordMx);
        padding = 0.2 * (maxLims - minLims);

        upperLims = maxLims + padding;
        lowerLims = minLims - padding;

        if ~isempty(Nwk.dia)
            maxDia = max(Nwk.dia);
            upperLims = upperLims + maxDia * 8;
            lowerLims = lowerLims - maxDia * 8;
        end

        xlims = get(ax, 'XLim');
        ylims = get(ax, 'YLim');
        zlims = get(ax, 'ZLim');
        
        xlDefault = [min(lowerLims(1), xlims(1)), max(upperLims(1), xlims(2))];
        ylDefault = [min(lowerLims(2), ylims(1)), max(upperLims(2), ylims(2))];
        zlDefault = [min(lowerLims(3), zlims(1)), max(upperLims(3), zlims(2))];
        ax.XLim = xlDefault;
        ax.YLim = ylDefault;
        ax.ZLim = zlDefault;
    end
    
    function snapshotCb(~, ~)

        % Generate filename based on current date and time
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        filename = ['snapshot_', timestamp, '.png'];       
        pathname = pwd; % Current working directory
        filepath = fullfile(pathname, filename);

        frame = getframe(axesFig);  % Capture figure
        imwrite(frame.cdata, filepath); %

        %saveas(axesFig, filepath, 'png'); % the figure view without the filename
        %exportgraphics(ax, filepath, 'ContentType', 'image', 'Resolution', 300); %the axes view
        disp(['File saved as: ', filepath]);
    end

    function writeToReport(text, ptList, faceList)
        fid = fopen('viewerReport.txt', 'a');        
        if fid == -1
            error('Unable to open or create report.txt');
        end

        currentTime = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
        fprintf(fid, '\n%s: %s\n', char(currentTime), text);
        if ~isempty(ptList)
            for i=1:length(ptList)
                fprintf(fid, '%s: %s\n', num2str(ptList(i)), num2str(activeNwk.ptCoordMx(ptList(i), :)));
            end
        end

        if ~isempty(faceList)
            for i=1:length(faceList)
                fprintf(fid, '%s: %s\n', num2str(faceList(i)), num2str(activeNwk.faceMx(faceList(i), :)));
            end
        end
        
    end

    function boundingBoxCb(~, ~)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        if  boundingBoxOn.Value
        
            % Define padding percentage
            padding = 0.1;
            
            % Determine bounding box limits
            minX = min(activeNwk.ptCoordMx(:, 1));
            maxX = max(activeNwk.ptCoordMx(:, 1));
            minY = min(activeNwk.ptCoordMx(:, 2));
            maxY = max(activeNwk.ptCoordMx(:, 2));
            minZ = min(activeNwk.ptCoordMx(:, 3));
            maxZ = max(activeNwk.ptCoordMx(:, 3));
            
            % Calculate range for each dimension
            rangeX = maxX - minX;
            rangeY = maxY - minY;
            rangeZ = maxZ - minZ;
            
            % Apply padding to the range
            minX = minX - padding * rangeX;
            maxX = maxX + padding * rangeX;
            minY = minY - padding * rangeY;
            maxY = maxY + padding * rangeY;
            minZ = minZ - padding * rangeZ;
            maxZ = max(maxZ + padding * rangeZ, 1);
    
            % Define vertices of the bounding box
            vertices = [
                minX, minY, minZ;
                maxX, minY, minZ;
                maxX, maxY, minZ;
                minX, maxY, minZ;
                minX, minY, maxZ;
                maxX, minY, maxZ;
                maxX, maxY, maxZ;
                minX, maxY, maxZ
            ];
    
            % Define the edges of the bounding box
            edges = [ 1, 2; 2, 3; 3, 4; 4, 1; 5, 6; 6, 7; 7, 8;
                      8, 5; 1, 5; 2, 6; 3, 7; 4, 8];

            bbGraph = graph(edges(:,1), edges(:,2));
    
            hold(ax, "on");
            bbHandle = plot(bbGraph, 'XData', vertices(:, 1), 'YData', vertices(:, 2),...
                'ZData', vertices(:, 3), 'EdgeColor', 'k',... 
                'NodeColor', '[0.95 0.95 0.95]', 'LineWidth', 2, 'EdgeAlpha', 0.1, ...
                'NodeLabel', {});
            hold(ax, "off");
            rendererTable.boxHandle{activeIdx} = bbHandle;

        else
            delete(rendererTable.boxHandle{activeIdx});
        end

        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end

    function labelsOnCb(~, ~)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        % Always shows only 100 labels
        tic;
        ptThreshold = 100;
        faceThreshold = 100;
        isLargeNwk = activeNwk.np > ptThreshold || activeNwk.nf > faceThreshold;

        if strcmp(activeHandle.UserData(1).type, 'cylinders')
            disp('Labelling not supported for cylinders yet');
            return
        end    

        if labelsOn.Value

            stepPt = round(activeNwk.np / 100); 
            stepFace = round(activeNwk.nf / 100);

            ptLabels = repmat({''}, size(activeG.Nodes, 1), 1);
            faceLabels = repmat({''}, size(activeG.Edges, 1), 1);

            if isLargeNwk
                ptLabels(1:stepPt:end) = strcat('P', arrayfun(@num2str, activeG.Nodes.Labels(1:stepPt:end), 'UniformOutput', false));
                faceLabels(1:stepFace:end) = strcat('F', arrayfun(@num2str, activeG.Edges.Weight(1:stepFace:end), 'UniformOutput', false));
            else
                ptLabels = strcat('P', arrayfun(@num2str, activeG.Nodes.Labels, 'UniformOutput', false));
                faceLabels = strcat('F', arrayfun(@num2str, activeG.Edges.Weight, 'UniformOutput', false));
            end
            
            set(activeHandle, 'NodeLabel', ptLabels, 'EdgeLabel', faceLabels);

            elapsedTime = toc;
            fprintf('Time taken for labelling: %.2f seconds\n', elapsedTime);
        
        elseif contains(activeHandle.UserData(1).type, 'graph')
            set(activeHandle, 'NodeLabel', '', 'EdgeLabel', '');
        end

        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end

    function directionsOnCb(~, ~)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';
        
        if directionsOn.Value && strcmp(activeHandle.UserData(1).type, 'graph') || ~directionsOn.Value && strcmp(activeHandle.UserData(1).type, 'digraph')
            plotGraph();
            updateEndPoints();
            updateEndFaces(); % This calls recoloring of groups inside it
        elseif directionsOn.Value && strcmp(activeHandle.UserData(1).type, 'subgraph') || ~directionsOn.Value && strcmp(activeHandle.UserData(1).type, 'disubgraph')

            if isfield(activeHandle.UserData, 'groups') && ~isempty(activeHandle.UserData(1).groups)
                  faceGrpEditCb();
            elseif  ~isempty(ptEditBox.Value) || ~isempty(faceEditBox.Value)
                  updateSelections();
            end

        end

        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end    


    function updateEndPoints(~, ~)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        if ~contains(activeHandle.UserData(1).type, 'graph')
            return;
        end

        [inlet, outlet] = nwkHelp.findBoundaryNodes(activeNwk);

        if strcmp(activeHandle.UserData(1).type, 'subgraph')
            subInlet = find(ismember(activeG.Nodes.Labels, inlet));
            subOutlet = find(ismember(activeG.Nodes.Labels, outlet));
        end

        if strcmp(endpointsGrp.SelectedObject.Text, 'None')

            if strcmp(activeHandle.UserData(1).type, 'subgraph')
                highlight(activeHandle, subInlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
                highlight(activeHandle, subOutlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            elseif strcmp(activeHandle.UserData(1).type, 'graph')
                highlight(activeHandle, inlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
                highlight(activeHandle, outlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            end

            if ~labelsOn.Value
                set(activeHandle, 'NodeLabel', {});
            end

        elseif strcmp(endpointsGrp.SelectedObject.Text, 'InletPoints')
            
            if strcmp(activeHandle.UserData(1).type, 'subgraph')
                highlight(activeHandle, subInlet, 'NodeColor', 'red', 'MarkerSize', 8);
                highlight(activeHandle, subOutlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            elseif strcmp(activeHandle.UserData(1).type, 'graph')
                highlight(activeHandle, inlet, 'NodeColor', 'red', 'MarkerSize', 8);
                highlight(activeHandle, outlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            end

            selectionLabels(inlet, []);
            writeToReport('Selected inlet points: ', inlet, []);

        elseif strcmp(endpointsGrp.SelectedObject.Text, 'OutletPoints')

            if strcmp(activeHandle.UserData(1).type, 'subgraph')
                highlight(activeHandle, subOutlet, 'NodeColor', 'blue', 'MarkerSize', 8); 
                highlight(activeHandle, subInlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            elseif strcmp(activeHandle.UserData(1).type, 'graph')
                highlight(activeHandle, outlet, 'NodeColor', 'blue', 'MarkerSize', 8); 
                highlight(activeHandle, inlet, 'NodeColor', nodeColor, 'MarkerSize', 2);
            end

            selectionLabels(outlet, []);
            writeToReport('Selected outlet points: ', outlet, []);

        elseif strcmp(endpointsGrp.SelectedObject.Text, 'All EndPoints')

            if strcmp(activeHandle.UserData(1).type, 'subgraph')
                highlight(activeHandle, subInlet, 'NodeColor', 'red', 'MarkerSize', 8);
                highlight(activeHandle, subOutlet, 'NodeColor', 'blue', 'MarkerSize', 8);
            elseif strcmp(activeHandle.UserData(1).type, 'graph')
                highlight(activeHandle, inlet, 'NodeColor', 'red', 'MarkerSize', 8);
                highlight(activeHandle, outlet, 'NodeColor', 'blue', 'MarkerSize', 8);
            end

            selectionLabels([inlet, outlet], []);
            writeToReport('Selected inlet and outlet points: ', [inlet, outlet], []);

        end

        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';

    end

    function updateEndFaces(~, ~)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        if ~contains(activeHandle.UserData(1).type, 'graph')
            return;
        end

        set(activeHandle, 'LineWidth', 2);
        reColorGrps();

        [inlet, outlet] = nwkHelp.findBoundaryFaces(activeNwk);

        if strcmp(activeHandle.UserData(1).type, 'subgraph')
            subInlet = find(ismember(activeG.Edges.Weight, inlet));
            subOutlet = find(ismember(activeG.Edges.Weight, outlet));
        end

        if strcmp(endfacesGrp.SelectedObject.Text, 'None')
            
            if ~labelsOn.Value
                set(activeHandle, 'EdgeLabel', {}); 
            end

        elseif strcmp(endfacesGrp.SelectedObject.Text, 'InletFaces')

            if strcmp(activeHandle.UserData(1).type, 'subgraph')
                highlight(activeHandle, activeNwk.faceMx(subInlet, 2), ...
                    activeNwk.faceMx(subInlet, 3), 'EdgeColor', 'red', 'LineWidth', 4);
            elseif strcmp(activeHandle.UserData(1).type, 'graph') 
                highlight(activeHandle, activeNwk.faceMx(inlet, 2), ...
                 activeNwk.faceMx(inlet, 3), 'EdgeColor', 'red', 'LineWidth', 4);
            end

            selectionLabels([], inlet);
            writeToReport('Selected inlet faces: ', [], inlet);
       
        elseif strcmp(endfacesGrp.SelectedObject.Text, 'OutletFaces')

            if strcmp(activeHandle.UserData(1).type, 'subgraph')
                 highlight(activeHandle, activeNwk.faceMx(subOutlet, 2),...
                    activeNwk.faceMx(subOutlet, 3), 'EdgeColor', 'blue', 'LineWidth', 4);
            elseif strcmp(activeHandle.UserData(1).type, 'graph')
                 highlight(activeHandle, activeNwk.faceMx(outlet, 2),...
                    activeNwk.faceMx(outlet, 3), 'EdgeColor', 'blue', 'LineWidth', 4);
            end

            selectionLabels([], outlet);
            writeToReport('Selected outlet faces: ', [], outlet);
        
        elseif strcmp(endfacesGrp.SelectedObject.Text, 'All EndFaces')
           
            if strcmp(activeHandle.UserData(1).type, 'subgraph')
                highlight(activeHandle, activeNwk.faceMx(subInlet, 2),...
                    activeNwk.faceMx(subInlet, 3), 'EdgeColor', 'red', 'LineWidth', 4);
                highlight(activeHandle, activeNwk.faceMx(subOutlet, 2),...
                    activeNwk.faceMx(subOutlet, 3), 'EdgeColor', 'blue', 'LineWidth', 4);
            elseif strcmp(activeHandle.UserData(1).type, 'graph')
                highlight(activeHandle, activeNwk.faceMx(inlet, 2),...
                    activeNwk.faceMx(inlet, 3), 'EdgeColor', 'red', 'LineWidth', 4);
                highlight(activeHandle, activeNwk.faceMx(outlet, 2),...
                    activeNwk.faceMx(outlet, 3), 'EdgeColor', 'blue', 'LineWidth', 4);
            end

            selectionLabels([], [inlet, outlet]);
            writeToReport('Selected end faces: ', [], [inlet, outlet]);
        end

    end

    set(axesFig, 'WindowButtonDownFcn', @mouseClickCb);
    global initialMousePos;
    
    function mouseClickCb(src, ~)

        if strcmp(src.SelectionType, 'normal') % Right mouse click
            set(axesFig, 'WindowButtonMotionFcn', @rotateCb);
        elseif strcmp(src.SelectionType, 'alt') % Left mouse click
            set(axesFig, 'WindowButtonMotionFcn', @moveHorizVertCb);
        end
        
        set(axesFig, 'WindowButtonUpFcn', @stopMovingCb);

    end

    function stopMovingCb(~, ~)
        set(axesFig, 'WindowButtonMotionFcn', '');
        set(axesFig, 'WindowButtonUpFcn', '');
        initialMousePos = [];        
    end

    % Assign the callback function to the mouse scroll wheel event
    set(axesFig, 'WindowScrollWheelFcn', @camZoomCb);

    
    % Move camera horizantally and vertically
    function moveHorizVertCb(src, ~)
        
        if isempty(initialMousePos)
            initialMousePos = get(src, 'CurrentPoint');
            return;
        end
        
        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        currentMousePos = get(src, 'CurrentPoint');
        dx = currentMousePos(1) - initialMousePos(1);
        dy = currentMousePos(2) - initialMousePos(2);
        camdolly(ax, -dx, -dy, 0, 'movetarget', 'pixels');
            
         % Update initial mouse position for next callback
        initialMousePos = currentMousePos;


        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end
    
    
    % Rotate the camera
    function rotateCb(src, ~)

       fig.Pointer = 'watch'; axesFig.Pointer = 'watch';
       
       if isempty(initialMousePos)
           initialMousePos = get(src, 'CurrentPoint');
           return;
       end
        
       currentMousePos = get(src, 'CurrentPoint');
       dx = currentMousePos(1) - initialMousePos(1);
       dy = currentMousePos(2) - initialMousePos(2);
       camorbit(ax, -dx, -dy, 'camera');
        
       % Update initial mouse position for next callback
       initialMousePos = currentMousePos;


       fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end
    
    minZoomDist = 1;
    maxZoomDist = 100000;

    % Zoom camera in and out
    function camZoomCb(~, event)
        % Scroll distance is +ve for scrolling up, -ve for scrolling down
        scrollDist = event.VerticalScrollCount;

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';
    
        % Fraction of total distance to move the camera
        fraction = 0.1;
        
        camPos = get(ax, 'CameraPosition');
        camTarget = get(ax, 'CameraTarget');
        newCamPos = camPos - scrollDist * fraction * (camPos - camTarget);

        
        newZoomDist = norm(newCamPos - camTarget);
        if newZoomDist >= minZoomDist && newZoomDist <= maxZoomDist
            set(ax, 'CameraViewAngleMode', 'manual', 'CameraPosition', newCamPos);
        end
       
        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';

    end

    % Callback function for the checkbox
    function faceSelectCb(~, ~)

        if ~contains(activeHandle.UserData(1).type, 'graph')
            return;
        end

        dcm_obj = datacursormode(axesFig);
        if ptSelect.Value
            ptSelect.Value = false;
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2);
        end
        if faceSelect.Value
            set(dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on', 'UpdateFcn', @highlightEdgesFromNearestNode);
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2, 'NodeLabel', {}, 'EdgeLabel', {});
        else
            set(dcm_obj, 'Enable', 'off', 'UpdateFcn', []);
            set(activeHandle, 'LineWidth', 2);
            reColorGrps();
            if labelsOn.Value
                labelsOnCb();
            end
        end
    end

    function txt = highlightEdgesFromNearestNode(~, event)

         ptCoords = event.Position;
         activeG = rendererTable.graphObj{activeIdx};
         ptRow = find(activeG.Nodes.X == ptCoords(1) & activeG.Nodes.Y == ptCoords(2) & activeG.Nodes.Z == ptCoords(3));
         ptIdx = activeG.Nodes.Labels(ptRow);
                  
         faceRows = find(activeG.Edges.EndNodes(:, 1) == ptRow | activeG.Edges.EndNodes(:, 2) == ptRow);
         faceIdx = activeG.Edges.Weight(faceRows);

         set(activeHandle, 'LineWidth', 2);
         reColorGrps();

         highlight(activeHandle, activeG.Edges.EndNodes(faceRows, 1), activeG.Edges.EndNodes(faceRows, 2), ...
             'EdgeColor', 'red', 'LineWidth', 4);

         writeToReport('Selected faces: ', [], faceIdx);
  
         txt=['p' num2str(ptIdx)];

         selectionLabels([], faceIdx);
    end

   
    % Callback function for the checkbox
    function ptSelectCb(~, ~)
        if ~contains(activeHandle.UserData(1).type, 'graph')
            return;
        end
 
        dcm_obj = datacursormode(axesFig);
        if faceSelect.Value
            faceSelect.Value = false;
            set(activeHandle, 'LineWidth', 2);
            reColorGrps();
        end
        if ptSelect.Value
            set(dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on', 'UpdateFcn', @selectPt);
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2, 'NodeLabel', {}, 'EdgeLabel', {});
        else
            set(dcm_obj, 'Enable', 'off', 'UpdateFcn', []);
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2);
            if labelsOn.Value
                labelsOnCb();
            end
        end
    end

    function selectionLabels(ptsIdx, facesIdx)
        activeG = rendererTable.graphObj{activeIdx};

        if ~isempty(ptsIdx)
            ptLabels = strings(height(activeG.Nodes), 1);
            for i = 1:length(ptsIdx)
                ptIdx = ptsIdx(i);
                matchingPt = find(activeG.Nodes.Labels == ptIdx);
                ptLabels(matchingPt) = ['P' num2str(ptIdx)];
            end
            activeHandle.NodeLabel = ptLabels;
        end

        if ~isempty(facesIdx)
            faceLabels = strings(height(activeG.Edges), 1);
            for i = 1:length(facesIdx)
                faceIdx = facesIdx(i);
                matchingFace = find(activeG.Edges.Weight == faceIdx);
                faceLabels(matchingFace) = ['F' num2str(faceIdx)];
            end
            activeHandle.EdgeLabel = faceLabels;
        end
    end    


    function txt = selectPt(~, event)
         ptCoords = event.Position;

         activeG = rendererTable.graphObj{activeIdx};
         ptRow = find(activeG.Nodes.X == ptCoords(1) & activeG.Nodes.Y == ptCoords(2) & activeG.Nodes.Z == ptCoords(3));
         ptIndex = activeG.Nodes.Labels(ptRow);

         set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2);
         highlight(activeHandle, ptRow, 'NodeColor', 'red', 'MarkerSize', 8);
         
         writeToReport('Selected points: ', ptIndex, []);

         txt = ['Node ', num2str(ptIndex)];
    end

    function updateSelections(~, ~)

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

        ptSelections = ptEditCb();
        faceSelections = faceEditCb();

        if isempty(ptSelections) && isempty(faceSelections)
            disp('Selection operation cancelled. Empty faceEdit and pointEdit');
            fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
            return;
        end

        if selectionRb2.Value
            
            plotSubsetFacesPts(faceSelections, ptSelections);
            reColorGrps(); %commented out for Emilie

            try
                activeHandle.UserData(1).selections = {strjoin(ptEditBox.Value, ''), strjoin(faceEditBox.Value, ''), 2};
                activeHandle.UserData(2).groups = [];
            catch ME 
            end

        elseif selectionRb3.Value
            
            ptSelections = setdiff(1:activeNwk.np, ptSelections)';
            faceSelections = setdiff(1:activeNwk.nf, faceSelections)';

            plotSubsetFacesPts(faceSelections, ptSelections);
            reColorGrps(); %commented out for Emilie

            try
                activeHandle.UserData(1).selections = {strjoin(ptEditBox.Value, ''), strjoin(faceEditBox.Value, ''), 3};
                activeHandle.UserData(2).groups = [];
            catch ME
            end

        else    

            % End points/faces highlights will be gone

            plotGraph();

            % Color everything black, except the green highlights
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2);
            set(activeHandle, 'EdgeColor', 'black', 'LineWidth', 2);

            highlight(activeHandle, ptSelections, 'NodeColor', 'green', 'MarkerSize', 8);
            faceRows = find(ismember(activeG.Edges.Weight(:), faceSelections));
            highlight(activeHandle, activeG.Edges.EndNodes(faceRows, 1),...
                activeG.Edges.EndNodes(faceRows, 2), 'EdgeColor', 'green', 'LineWidth', 4);

            activeHandle.UserData(1).selections = {strjoin(ptEditBox.Value, ''), strjoin(faceEditBox.Value, ''), 1};
            activeHandle.UserData(2).groups = [];

        end

        %if ~isempty(ptSelections) || ~isempty(faceSelections)
        %    writeToReport('Selected points and faces: ', ptSelections, faceSelections);
        %end

        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';

    end

    function resetSelections(~, ~)
        selectionRb2.Value = false;
        selectionRb1.Value = true;
        selectionRb3.Value = false;

        faceEditBox.Value = '';
        ptEditBox.Value = '';
        
        if ~isempty(activeHandle) && contains(activeHandle.UserData(1).type, 'subgraph')
            plotGraph(); 
        end
        % elseif strcmp(activeHandle.UserData.type, 'graph') || strcmp(activeHandle.UserData.type, 'digraph')
        %    set(activeHandle, 'NodeColor', 'k', 'MarkerSize', 2);
        %    set(activeHandle, 'LineWidth', 2);
        %    reColorGrps();
        % end

        reApplyHighlights();
        
    end

    function editSelections(~, ~)

        ptSelections = ptEditCb();
        faceSelections = faceEditCb();

        if isempty(ptSelections) && isempty(faceSelections)
            disp('Edit operation cancelled. Empty faceEdit and pointEdit');
            return;
        end
        
        editFig = figure('Name', 'Edit Faces', 'Position', [500, 300, 450, 800], ...
            'NumberTitle', 'off', 'Scrollable', 'on', 'MenuBar','none');

        % Display the matrix
        faceTmp = [num2cell(int32(activeNwk.faceMx(faceSelections, 1))), ...
            num2cell(int32(activeNwk.faceMx(faceSelections, 2))), ...
            num2cell(int32(activeNwk.faceMx(faceSelections, 3))), ...
            num2cell(double(activeNwk.dia(faceSelections)))];
        ptTmp = activeNwk.ptCoordMx(ptSelections, 1:3);

        uicontrol(editFig, 'Style', 'text', 'String', 'Face Selection Matrix:', ...
            'Position', [20, 760, 410, 20], 'HorizontalAlignment', 'left', 'FontSize', 12);

        faceTable = uitable(editFig, 'Data', faceTmp, 'Position', [20, 600, 410, 160], ...
            'ColumnEditable', true, 'ColumnName', {'Group ID' ; 'Pt Index1' ; 'Pt Index2' ; 'Diameter'}, ...
            'ColumnWidth', {100, 100, 100, 100}, 'RowName', {faceSelections}, ...
            'BackgroundColor', [0.9 0.9 0.9; 1 1 1], 'ForegroundColor', [0 0 0]);

        uicontrol(editFig, 'Style', 'text', 'String', 'Point Selection Matrix:', ...
            'Position', [20, 560, 410, 20], 'HorizontalAlignment', 'left', 'FontSize', 12);

        ptTable = uitable(editFig, 'Data', ptTmp, 'Position', [20, 400, 410, 160], ...
           'ColumnEditable', true, 'ColumnName', {'X', 'Y', 'Z'},  'ColumnWidth', {133, 133, 133}, ...
           'RowName', {ptSelections}, 'BackgroundColor', [0.9 0.9 0.9; 1 1 1], 'ForegroundColor', [0 0 0]);

        uicontrol(editFig, 'Style', 'text', 'String', 'Face Selection Indexes:', ...
            'Position', [20, 360, 410, 20], 'HorizontalAlignment', 'left', 'FontSize', 12);

        faceSelectionField = uicontrol(editFig, 'Style', 'edit', 'Max', 2, 'String', strjoin(string(faceSelections), ','), ...
            'Position', [20, 240, 410, 120], 'HorizontalAlignment', 'left');
        
        % uitextarea(editFig, 'Value', strjoin(string(faceSelections), ','), ...
        % 'Position', [20, 240, 460, 120], 'Editable', 'on', 'HorizontalAlignment', 'left', 'WordWrap', 'on');

        uicontrol(editFig, 'Style', 'text', 'String', 'Point Selection Indexes:', ...
            'Position', [20, 200, 410, 20], 'HorizontalAlignment', 'left', 'FontSize', 12 ...
            );


        ptSelectionField = uicontrol(editFig, 'Style', 'edit', 'Max', 2, 'String', strjoin(string(ptSelections), ','), ...
            'Position', [20, 80, 410, 120], 'HorizontalAlignment', 'left');

        % Create Save button
        applyEditsBtn = uicontrol(editFig, 'Style', 'pushbutton', 'String', 'Apply', ...
            'Position', [50, 30, 80, 30], 'Callback', @(~, ~) applyEditCb());

        % Create Cancel button
        cancelBtn = uicontrol(editFig, 'Style', 'pushbutton', 'String', 'Cancel', ...
            'Position', [150, 30, 80, 30], 'Callback', @(~, ~) close(editFig));

        % Nested function to save changes
        function applyEditCb()
            faceEditedData = faceTable.Data;

            activeNwk.faceMx(faceSelections, 1) = cell2mat(faceEditedData(:, 1));
            activeNwk.faceMx(faceSelections, 2) = cell2mat(faceEditedData(:, 2));
            activeNwk.faceMx(faceSelections, 3) = cell2mat(faceEditedData(:, 3));
            activeNwk.dia(faceSelections) = cell2mat(faceEditedData(:, 4));

            ptEditedData = ptTable.Data;
            activeNwk.ptCoordMx(ptSelections, 1:3) = ptEditedData(:, 1:3);

            rendererTable.nwkObj{activeIdx} = activeNwk;

            updateSelections();
            initGroupBox();

            % % reApplyUIOptions();
            % reApplyHighlights();

            close(editFig);
        end
    end

    function shortestPathCb(~, ~)

        if ~contains(activeHandle.UserData(1).type, 'graph')
            return;
        end

        dcm_obj = datacursormode(axesFig);
        if shortestPathSelect.Value
            set(dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on', 'UpdateFcn', @Pts4Paths);
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2, 'LineWidth', 2, 'NodeLabel', {}, 'EdgeLabel', {});
        else
            set(dcm_obj, 'Enable', 'off', 'UpdateFcn', []);
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2, 'LineWidth', 2);
            reColorGrps();
        end

    end

    function txt = Pts4Paths(~, event)
        ptCoords = event.Position;
        
        activeG = rendererTable.graphObj{activeIdx};
        ptRow = find(activeG.Nodes.X == ptCoords(1) & activeG.Nodes.Y == ptCoords(2) & ...
                     activeG.Nodes.Z == ptCoords(3));
        ptIndex = activeG.Nodes.Labels(ptRow);
        txt = ['Node ', num2str(ptIndex)];

        highlight(activeHandle, ptRow, 'NodeColor', 'red', 'MarkerSize', 8);
        twoPts4Paths = [twoPts4Paths, ptRow];

        if isscalar(twoPts4Paths)

            % Reset previous highlighted, then highlight the point
            set(activeHandle, 'NodeColor', nodeColor, 'EdgeColor', 'black', 'LineWidth', 2, 'MarkerSize', 2); 
            highlight(activeHandle, ptRow, 'NodeColor', 'red', 'MarkerSize', 8);

        elseif length(twoPts4Paths) == 2

            highlight(activeHandle, ptRow, 'NodeColor', 'red', 'MarkerSize', 8);
       
            origWt = activeG.Edges.Weight;
            [sn, tn] = findedge(activeG);
            dx = activeG.Nodes.X(sn) - activeG.Nodes.X(tn);
            dy = activeG.Nodes.Y(sn) - activeG.Nodes.Y(tn);
            dz = activeG.Nodes.Z(sn) - activeG.Nodes.Z(tn);
            faceLen = sqrt(dx.^2 + dy.^2 + dz.^2);
            activeG.Edges.Weight = faceLen;

            pathPts = shortestpath(activeG, twoPts4Paths(1), twoPts4Paths(2)); 
            highlight(activeHandle, pathPts, 'NodeColor', 'green', 'EdgeColor', 'green', 'LineWidth', 6);
            activeG.Edges.Weight = origWt;
            writeToReport('Points on the shortest path: ', pathPts, []);
            %selectionLabels(pathPts, []);

            twoPts4Paths = [];
        end
    end

    function multiSelectCb(~, ~)
        
        if ~contains(activeHandle.UserData(1).type, 'graph')
            return;
        end

        twoPts4MultiSelect = []; multiSelectFaceIdx = [];
        dcm_obj = datacursormode(axesFig);
        if multiSelect.Value
            set(dcm_obj, 'DisplayStyle', 'datatip', 'Enable', 'on', 'UpdateFcn', @multiSelectPath);
            set(activeHandle, 'NodeColor', nodeColor, 'EdgeColor', 'black', 'MarkerSize', 2, 'LineWidth', 2, 'NodeLabel', {}, 'EdgeLabel', {});
        else
            set(dcm_obj, 'Enable', 'off', 'UpdateFcn', []);
            set(activeHandle, 'NodeColor', nodeColor, 'MarkerSize', 2, 'LineWidth', 2);
            set([selectedFaces,groupIdBox], 'String', '');
            reColorGrps();
        end
    end

    function txt = multiSelectPath(~, event)

        ptCoords = event.Position;
        
        activeG = rendererTable.graphObj{activeIdx};
        ptRow = find(activeG.Nodes.X == ptCoords(1) & activeG.Nodes.Y == ptCoords(2) & ...
                     activeG.Nodes.Z == ptCoords(3));
        ptIndex = activeG.Nodes.Labels(ptRow);
        txt = ['Node ', num2str(ptIndex)];

        highlight(activeHandle, ptRow, 'NodeColor', 'red', 'MarkerSize', 8);
        twoPts4MultiSelect = [twoPts4MultiSelect, ptRow];

          if length(twoPts4MultiSelect) == 2

                origWt = activeG.Edges.Weight;
                [sn, tn] = findedge(activeG);
                dx = activeG.Nodes.X(sn) - activeG.Nodes.X(tn);
                dy = activeG.Nodes.Y(sn) - activeG.Nodes.Y(tn);
                dz = activeG.Nodes.Z(sn) - activeG.Nodes.Z(tn);
                faceLen = sqrt(dx.^2 + dy.^2 + dz.^2);
                activeG.Edges.Weight = faceLen;
        
                pathPts = shortestpath(activeG, twoPts4MultiSelect(1), twoPts4MultiSelect(2)); 
                activeG.Edges.Weight = origWt;

                if (isempty(pathPts))
                    highlight(activeHandle, twoPts4MultiSelect, 'NodeColor', nodeColor, 'MarkerSize', 2);
                    twoPts4MultiSelect = [];
                    disp('No path between the 2 points');
                    return;
                end

                highlight(activeHandle, pathPts, 'NodeColor', 'green', 'EdgeColor', 'green', 'LineWidth', 6);
        
                faceIdx = findedge(activeG, pathPts(1:end-1), pathPts(2:end));
                origFaceIdx = activeG.Edges.Weight(faceIdx);
                multiSelectFaceIdx = [multiSelectFaceIdx; origFaceIdx];
                multiSelectFaceIdx = unique(multiSelectFaceIdx);

                set(selectedFaces, 'String', strjoin(string(multiSelectFaceIdx), ','));
                twoPts4MultiSelect = [];
          elseif length(twoPts4MultiSelect) > 2
               highlight(activeHandle, twoPts4MultiSelect, 'NodeColor', nodeColor, 'MarkerSize', 2);
               twoPts4MultiSelect = [];
          end
    end

    function deleteFacesCb(~, ~)

        % Get face indices from the text box
        inputStr = selectedFaces.String;
        inputStr = strsplit(inputStr, ','); 
        faceIndices = str2double(inputStr);

        if (isnan(faceIndices))
            return;
        end

        % update activeG
        GEdges = find(ismember(activeG.Edges.Weight, faceIndices));
        activeG = rmedge(activeG, activeG.Edges.EndNodes(GEdges, 1), activeG.Edges.EndNodes(GEdges, 2));
        rendererTable{activeIdx, 5} = {activeG};

        % update active handle of graph plot
        updateActivePlot();
        reColorGrps();
    end


    function assignGroupCb(~, ~)

        % Get face indices from the text box
        inputStr = selectedFaces.String;
        inputStr = strsplit(inputStr, ','); 
        faceIndices = str2double(inputStr);

        grpId = str2num(groupIdBox.String);
        
        if any(isnan(faceIndices)) || any(isnan(grpId))
            return;
        end

        activeNwk.faceMx(faceIndices, 1) = ones(size(faceIndices, 2), 1) * grpId;
        rendererTable.nwkObj{activeIdx} = activeNwk;

        initGroupBox();
        reColorGrps();

        set(groupIdBox, 'String', '');

        % % reApplyUIOptions();
        % reApplyHighlights();

    end

    function connectedCompCb(~, ~)
    
        persistent compFig;

        if connectedComp.Value
            compFig = figure('Name', 'Connected Components - Number of Nodes/Edges', 'Position', [100 100 600 400]);
            compTypeDropdown = uicontrol('Style', 'popupmenu', 'String', {'Points', 'Faces'}, 'Position', [500 380 90 15], ...
                                         'Callback', @updateBarGraph);

            compNodeIdx = conncomp(activeG, 'Type', 'weak');
            nc = max(compNodeIdx); % nc is number of components
            compColors = lines(nc);
            [src, dest] = findedge(activeG);
    
            numPtsPerComp = zeros(1, nc);
            numFacesPerComp = zeros(1, nc);
    
            for i = 1:nc
                facesComp = find(compNodeIdx(src) == compNodeIdx(dest) & compNodeIdx(src) == i);
                highlight(activeHandle, 'Edges', facesComp, 'EdgeColor', compColors(i, :), 'LineWidth', 4);
                
                hd = sprintf('Points and Faces in Connected component %d : ', i);
                pId = find(compNodeIdx == i); pIdLabels = activeG.Nodes.Labels(pId); fId = activeG.Edges.Weight(facesComp);
                writeToReport(hd, pIdLabels, fId);
    
                numPtsPerComp(i) = length(pId);
                numFacesPerComp(i) = length(facesComp);
            end
    
            updateBarGraph(compTypeDropdown); % Initial plot with "Points" as default
    
        else        
            reColorGrps();
            set(activeHandle, 'LineWidth', 2);

            if ~isempty(compFig) && isvalid(compFig)
                close(compFig); compFig = [];
            end
        end
    
        function updateBarGraph(src, ~)
            selectedType = src.Value;
            clf(compFig);
            compTypeDropdown = uicontrol('Style', 'popupmenu', 'String', {'Points', 'Faces'}, 'Value', selectedType, ...
                'Position', [500 380 90 15],  'Callback', @updateBarGraph);
    
            if selectedType == 1
                bar(1:nc, numPtsPerComp, 'FaceColor', 'flat');
                ylabel('Number of Points');
            elseif selectedType == 2
                bar(1:nc, numFacesPerComp, 'FaceColor', 'flat');
                ylabel('Number of Faces');
            end
    
            xlabel('Component Index'); title('Number of Points/Faces in Each Connected Component');
            xticks(1:nc); colormap(compColors);  % Apply the same color scheme
        end
    
    
    end

    function [ptsList] = ptEditCb()
        input_str = strjoin(ptEditBox.Value, '');
        input_str = strrep(input_str, ' ', '');  % Remove whitespace
        input_values = strsplit(input_str, ',');  % Split by comma
        
        ptsList = [];        
        for i = 1:numel(input_values)
            value = input_values{i};
            
            if contains(value, '&')
                conditions = strsplit(value, '&');
                tempPtsList = 1:activeNwk.np;
                for j = 1:numel(conditions)
                    condition = conditions{j};
                    tempPtsList = intersect(tempPtsList, parsePtCondition(condition));
                end
                ptsList = union(ptsList, tempPtsList);
            else
                ptsList = union(ptsList, parsePtCondition(value));
            end
        end
    
        if ~isempty(ptsList)
            ptsList = sort(ptsList, 1);
        end
    end

    function [faceList] = faceEditCb()

        input_str = strjoin(faceEditBox.Value, '');
        input_str = strrep(input_str, ' ', '');
        input_values = strsplit(input_str, ',');
        
        faceList = [];
        
        for i = 1:numel(input_values)
            value = input_values{i};
            
            if contains(value, '&')
                conditions = strsplit(value, '&');
                tempFaceList = 1:activeNwk.nf;
                for j = 1:numel(conditions)
                    condition = conditions{j};
                    tempFaceList = intersect(tempFaceList, parseFaceCondition(condition));
                end
                faceList = union(faceList, tempFaceList);
            else
                faceList = union(faceList, parseFaceCondition(value));
            end
        end

        if ~isempty(faceList)
            faceList = sort(faceList, 1);
        end
    end

    function faceGrpEditCb(~, ~)
 
        checkedGroupIDs = findCheckedGrpIds();
        facesList = find(ismember(activeNwk.faceMx(:, 1), checkedGroupIDs));


        if size(facesList, 1) == activeNwk.nf

             if toggleCylindersView.Value
                 togglePlotCb([], [], (1:activeNwk.nf)', activeNwk.dia);
             else
                plotGraph();
                updateEndPoints();
                updateEndFaces(); % Inside this endfaces - we call recoloring based on groups
             end

        elseif size(facesList, 1) == 0
            disp('Tick a group`s checkbox and try again');
            return;
        else
             if toggleCylindersView.Value
                 togglePlotCb([], [], facesList, activeNwk.dia);
             else
                plotSubsetFacesPts(facesList, []);
                reColorGrps();
             end

            if selectionRb1.Value
                val = 1;
            elseif selectionRb2.Value    
                val = 2;
            else
                val = 3;
            end
            try
                activeHandle.UserData(1).selections = {strjoin(ptEditBox.Value, ''), strjoin(faceEditBox.Value, ''), val};
                activeHandle.UserData(1).groups = checkedGroupIDs;
            catch ME
            end
 
        end
        
    end

    function plotSubsetFacesPts(facesList, ptsList)

            uniquePts = [];

            fig.Pointer = 'watch'; axesFig.Pointer = 'watch';

            if directionsOn.Value
                subG = digraph([], []);
                type = 'disubgraph';
            else
                subG = graph([], []);
                type = 'subgraph';
            end

            if (strcmp(andOrBtn.Text, 'AND'))

                % Code for Doing a AND / Intersection of faceEdit and PtEdit
                if (isempty(ptsList))
                    ptsList = unique(activeNwk.faceMx(facesList, 2:3));
                end

                if ~isempty(facesList) && ~isempty(ptsList)
                    endpoints = activeNwk.faceMx(facesList, 2:3);
                    % Faces that have atleast one endpoint in selcted points - use all or any function
                    validFaces = any(ismember(endpoints, ptsList), 2);
                    filteredFacesList = facesList(validFaces);
                    
                    if ~isempty(filteredFacesList)
                        uniquePts = unique(activeNwk.faceMx(filteredFacesList, 2:3));
                        
                        [~, newInlet] = ismember(activeNwk.faceMx(filteredFacesList, 2), uniquePts);
                        [~, newOutlet] = ismember(activeNwk.faceMx(filteredFacesList, 3), uniquePts);
                        newFaces = [newInlet, newOutlet, filteredFacesList(:)];
                        
                        if directionsOn.Value
                            subG = digraph(newFaces(:,1), newFaces(:,2), newFaces(:,3));
                        else
                            subG = graph(newFaces(:,1), newFaces(:,2), newFaces(:,3));
                        end
                        
                        subG.Nodes.X = activeNwk.ptCoordMx(uniquePts, 1);
                        subG.Nodes.Y = activeNwk.ptCoordMx(uniquePts, 2);
                        subG.Nodes.Z = activeNwk.ptCoordMx(uniquePts, 3);
                        subG.Nodes.Labels = uniquePts(:);
                    end
                elseif (isempty(facesList) && ~isempty(ptsList))
                    uniquePts = unique(ptsList);
                    subG = addnode(subG, size(uniquePts, 1));
                    subG.Nodes.X = activeNwk.ptCoordMx(uniquePts, 1);
                    subG.Nodes.Y = activeNwk.ptCoordMx(uniquePts, 2);
                    subG.Nodes.Z = activeNwk.ptCoordMx(uniquePts, 3);
                    subG.Nodes.Labels = uniquePts(:);
                end

            else

                % Code for Doing a OR / Union of faceEdit and PtEdit
                if ~isempty(facesList)
                    uniquePts = unique(activeNwk.faceMx(facesList, 2:3));
    
                    [~, newInlet] = ismember(activeNwk.faceMx(facesList, 2), uniquePts);
                    [~, newOutlet] = ismember(activeNwk.faceMx(facesList, 3), uniquePts);                
                    newFaces = [newInlet, newOutlet, facesList(:)];
    
                    if directionsOn.Value
                        subG = digraph(newFaces(:, 1), newFaces(:, 2), newFaces(:, 3));
                    else    
                        subG = graph(newFaces(:, 1), newFaces(:, 2), newFaces(:, 3));
                    end
    
                    subG.Nodes.X = activeNwk.ptCoordMx(uniquePts, 1);
                    subG.Nodes.Y = activeNwk.ptCoordMx(uniquePts, 2);
                    subG.Nodes.Z = activeNwk.ptCoordMx(uniquePts, 3);
                    subG.Nodes.Labels = uniquePts(:);
                end
    
                if ~isempty(ptsList)
                    diffPtsList = setdiff(ptsList, uniquePts);
                    subG = addnode(subG, size(diffPtsList, 1));     
                    np = size(uniquePts, 1)+1;
    
                    subG.Nodes.X(np: (np+length(diffPtsList)-1)) = activeNwk.ptCoordMx(diffPtsList, 1);
                    subG.Nodes.Y(np: (np+length(diffPtsList)-1)) = activeNwk.ptCoordMx(diffPtsList, 2);
                    subG.Nodes.Z(np: (np+length(diffPtsList)-1)) = activeNwk.ptCoordMx(diffPtsList, 3);
                    subG.Nodes.Labels(np: (np+length(diffPtsList)-1)) = diffPtsList;
                end
            end

            hold(ax, "on");

            if ~isempty(rendererTable.plotHandle{activeIdx})
                delete(rendererTable.plotHandle{activeIdx});
            end
            
            if ~isempty(subG.Nodes)
                activeHandle = plot(ax, subG, 'XData', subG.Nodes.X, ...
                    'YData', subG.Nodes.Y, 'ZData', subG.Nodes.Z, ...
                     'NodeColor', nodeColor, 'EdgeColor', 'k', 'NodeLabel', {}, ...
                     'MarkerSize', 2, 'LineWidth', 2) ;
                activeHandle.UserData = struct('type', '', 'selections', {}, 'groups', []);         
                activeHandle.UserData(1).type = type;


                activeG = subG;
                rendererTable{activeIdx, 4} = {activeHandle};
                rendererTable{activeIdx, 5} = {activeG};

                if labelsOn.Value
                    labelsOnCb();
                end
            end
            hold(ax, "off");

            activeG = subG;
            rendererTable{activeIdx, 4} = {activeHandle};
            rendererTable{activeIdx, 5} = {activeG};

            resetOnRedraw();

            drawnow;
            fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';

    end

   function delGrpCheckboxes()
       
        % Check if the tableGrpBoxes exists and is not empty
        if exist('tableGrpBoxes', 'var') && ~isempty(tableGrpBoxes)
            for i = 1:height(tableGrpBoxes)
                delete(tableGrpBoxes.grpBoxHandles{i});
                delete(tableGrpBoxes.colorPickers{i});
                delete(tableGrpBoxes.numFaces{i});
            end
        end
        delete(applyBtn); delete(resetBtn); delete(renameBtn);
        if exist('grpTitles', 'var') && ~isempty(grpTitles)
            delete(grpTitles.title{1}); delete(grpTitles.title{2}); delete(grpTitles.title{3});
        end
   end

    % Create a small PNG file to be viewed as ico file
    function createPngForIco(filePath)
        [path, name, ~] = fileparts(filePath);

        pngName = fullfile(path, [name, '.png']);

        if ~exist(pngName, 'file')

            tempFig = figure('Visible', 'off');
            set(tempFig, 'Position', [0, 0, 128, 128]);
            axCopy = copyobj(ax, tempFig);

            for i=1:size(axCopy.Children, 1)
                if isa(axCopy.Children(i), 'matlab.graphics.chart.primitive.GraphPlot')
                    axCopy.Children(i).NodeLabel = {};
                    axCopy.Children(i).EdgeLabel = {};
                end
            end

            frame = getframe(axCopy);
            imwrite(frame.cdata, pngName, 'png');
            
            close(tempFig);
            disp(['Created a PNG file for the loaded file: ', pngName]);
        end
    end
        
    function reColorGrps()

       if strcmp(activeHandle.UserData(1).type, 'cylinders')
           return
       end
        
        % Get group IDs for subset faces in active graph 
        % Get colors from grpColors dictionary, convert to matrix
        
        % update color changes in groups
        for i = 1:size(tableGrpBoxes, 1)
           rendererTable.grpColors{activeIdx}{tableGrpBoxes.colorPickers{i}.UserData} = tableGrpBoxes.colorPickers{i}.Value;
        end
        
        grpIds = activeNwk.faceMx(activeG.Edges.Weight(:), 1);
        faceColors = cell2mat(rendererTable.grpColors{activeIdx}(grpIds));

        set(activeHandle, 'EdgeColor', faceColors);

    end

    function indices = parseFaceCondition(condition)
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
                    indices = (value+1):activeNwk.nf;
                elseif strcmp(operator, '<')
                    indices = 1:(value-1);
                end

            elseif any(startsWith(condition, {'d', 'l', 'g', 'p1', 'p2'}))

                 if strcmp(condition(1), 'd')
                    searchCol = activeNwk.dia;

                 elseif strcmp(condition(1), 'l')
                    if ~isfield(activeNwk, 'faceLen')
                        activeNwk.faceLen = calculateLengths();
                    end
                    searchCol = activeNwk.faceLen;     
                 elseif strcmp(condition(1), 'g')
                    searchCol = activeNwk.faceMx(:, 1);
                 elseif strcmp(condition(1:2), 'p1')
                    searchCol = activeNwk.faceMx(:, 2);
                 elseif strcmp(condition(1:2), 'p2')
                    searchCol = activeNwk.faceMx(:, 3);
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
                if ~isnan(index) && index >= 1 && index <= activeNwk.nf
                    indices = index;
                elseif ~isempty(condition)
                    disp(['Invalid input: ', condition]);
                end
            end
        end
    end

    function lengths = calculateLengths()
        numFaces = size(activeNwk.faceMx, 1);
        lengths = zeros(numFaces, 1);
        for k = 1:numFaces
            pt1 = activeNwk.ptCoordMx(activeNwk.faceMx(k, 2), :);
            pt2 = activeNwk.ptCoordMx(activeNwk.faceMx(k, 3), :);
            lengths(k) = sqrt(sum((pt1 - pt2).^2));
        end
    end

    function indices = parsePtCondition(condition)
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
                    indices = (value+1):activeNwk.np;
                elseif strcmp(operator, '<')
                    indices = 1:(value-1);
                elseif contains(condition, '%')
                    indices = value:value:activeNwk.np;
                end

            elseif any(startsWith(condition, {'X', 'Y', 'Z', 'DGi', 'DGo', 'ls'}))

                if strcmp(condition(1), 'X')              
                    searchCol = activeNwk.ptCoordMx(:, 1);                
                elseif strcmp(condition(1), 'Y')                    
                    searchCol = activeNwk.ptCoordMx(:, 2);
                elseif strcmp(condition(1), 'Z')
                    searchCol = activeNwk.ptCoordMx(:, 3);

                elseif strcmp(condition(1:2), 'ls')     
                     if isfield(activeNwk, 'ls')
                        searchCol = activeNwk.ls;
                     else
                        disp('.ls file not found');
                        return;
                     end

                elseif strcmp(condition(1:3), 'DGi')
                    if ~isfield(activeNwk, 'inDeg')
                        [activeNwk.inDeg, activeNwk.outDeg] = calculateInOutDegree();
                    end
                    searchCol = activeNwk.inDeg;
                elseif strcmp(condition(1:3), 'DGo')
                    if ~isfield(activeNwk, 'outDeg')
                        [activeNwk.inDeg, activeNwk.outDeg] = calculateInOutDegree();
                    end
                    searchCol = activeNwk.outDeg;
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
                if ~isnan(index) && index >= 1 && index <= activeNwk.np
                    indices = index;
                elseif ~isempty(condition)
                    disp(['Invalid input: ', condition]);
                end
            
            end
        end
    end

    function [inDeg, outDeg] = calculateInOutDegree()
         C1= nwkSim.ConnectivityMx(activeNwk.nf, activeNwk.np, activeNwk.faceMx);
         [inDeg, outDeg] = nwkHelp.getNodeDegrees(activeNwk, C1);
    end

    % Function to close both figures
    function closeBothFig(~, ~)
        delete(fig);
        delete(axesFig);
    end
   
    function reApplyUIOptions()

        if boundingBoxOn.Value && isempty(rendererTable.boxHandle{activeIdx}) || ~boundingBoxOn.Value && ~isempty(rendererTable.boxHandle{activeIdx})
            boundingBoxCb();
        end

        if toggleCylindersView.Value && contains(activeHandle.UserData(1).type, 'graph') || ~toggleCylindersView.Value && strcmp(activeHandle.UserData(1).type, 'cylinders')
            togglePlotCb([], [], [], []);
        end

        directionsOnCb();
        
        labelsOnCb();

    end

    function resetOnRedraw()
    
        % Disable face or pt selection modes if it is set
        if ptSelect.Value
            ptSelect.Value = false;
            ptSelectCb();
        elseif faceSelect.Value
            faceSelect.Value = false;
            faceSelectCb();
        end

        ptNoneRb1.Value = true;
        facesRb1.Value = true;

        % if toggleCylindersView.Value
        %     toggleCylindersView.Value = false;
        %     colorbar('off');
        % end

    end    


    function reApplyHighlights()
        try
            if contains(activeHandle.UserData(1).type, 'subgraph')
                reColorGrps();
            elseif strcmp(activeHandle.UserData(1).type, 'graph') || strcmp(activeHandle.UserData(1).type, 'digraph')
    
                % % Prioritising selections over endpoints/endfaces
                if ~isempty(ptEditBox.Value) || ~isempty(faceEditBox.Value) 
                    updateSelections();
                else
                    faceGrpEditCb();
                end
                % 
                % if isfield(activeHandle.UserData, 'groups') && ~isempty(activeHandle.UserData(1).groups)
                %       faceGrpEditCb();
                % elseif  ~isempty(ptEditBox.Value) || ~isempty(faceEditBox.Value)
                %       updateSelections();
                % end
            end
        catch ME
            if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
                disp('Empty graph plot');
            else
                rethrow(ME);
            end
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

    function [grpIds] = selectLoadGrps()

       uniqueGroupIDs = unique(activeNwk.faceMx(:, 1));
        if size(uniqueGroupIDs, 1) == 1
            dynamicGrouping();
        end
        groupIDs = activeNwk.faceMx(:, 1);
        uniqueGroupIDs = unique(groupIDs);

        % Choose two groups with largest diameters
        % Compares 25th percentile of each group
        groupPercentiles = zeros(length(uniqueGroupIDs), 1);
        for i = 1:length(uniqueGroupIDs)
            groupIdx = groupIDs == uniqueGroupIDs(i);
            groupPercentiles(i) = prctile(activeNwk.dia(groupIdx), 25);
        end
        [~, sortedIdx] = sort(groupPercentiles);
        sortedGroupIds = uniqueGroupIDs(sortedIdx);
        grpIds = sortedGroupIds(end:-1:end-1)';

        if size(uniqueGroupIDs, 1) == 2
            grpIds = sortedGroupIds(end)';
        end

        % % Choose two groups with least number of faces
        % uniqueGroupIDs = unique(groupIDs);
        % groupCounts = arrayfun(@(x) sum(groupIDs == x), uniqueGroupIDs);
        % [~, sortedIdx] = sort(groupCounts);
        % smallestGroups = uniqueGroupIDs(sortedIdx(1:2));
        % grpIds = smallestGroups;
    end

    function resetColors(~, ~)

        % Delete existing colors, so new group area is created with predefined colors
        rendererTable.grpColors{activeIdx}([unique(activeNwk.faceMx(:,1))]) = [];
        initGroupBox();
        
        % Apply the new color changes to graph
        faceGrpEditCb();
    end

    function faceColors = prop2color(colorRange, propValues)
        normalizedProps = (propValues - min(propValues)) / (max(propValues) - min(propValues));
        colorIndices = min(round(normalizedProps * size(colorRange, 1)) + 1, size(colorRange, 1));
        faceColors = colorRange(colorIndices, :);
    end

    function updateFaceProp(~, ~)

        selectedIdx = find([colorGrp.Children.Value] == 1);

        % if grp selected, color based on groups
        if strcmp(colorGrp.Children(selectedIdx).Text, 'grp')    
            faceGrpEditCb();
            colorbar('off');
            return
        end

        faceProp = extractFaceProp();

        if toggleCylindersView.Value
            togglePlotCb([], [], [], faceProp);
        else
            if strcmp(activeHandle.UserData(1).type, 'cylinders')
                faceGrpEditCb();
            end 
            propValues = faceProp(activeG.Edges.Weight);
            faceColors = prop2color(jet(256), propValues);
            set(activeHandle, 'EdgeColor', faceColors);
            addColorbar(propValues);
        end    
    end

    function onTabSelection(~, ~)

        if size(rendererTable, 1) <= 0
            disp('Load a nwk and to open the available properties');
            return
        end

        if ~strcmp(colorTab.SelectedTab.Title, 'Properties')
            if ~isempty(colorGrp.Children)
                selectedIdx = find([colorGrp.Children.Value] == 1);
                if ~strcmp(colorGrp.Children(selectedIdx).Text, 'grp')
                    colorGrp.Children(end).Value = 1;
                    faceGrpEditCb();
                    colorbar('off');
                end
                return
            end
        end

        filename = rendererTable.fileName{activeIdx};
        [path, name, ~] = fileparts(filename);
        filename = fullfile(path, name);
        extensions = {'ff', 'ppAv', 'dia', 'pp'};
        positionY = 105;
    
        delete(colorGrp.Children);

        uiradiobutton(colorGrp, 'Text', 'grp', 'Value', true, ...
          'Position', [10, positionY, 50, 20]);
        positionY = positionY - 25;

        for i = 1:length(extensions)
            fullFilename = strcat(filename, '.', extensions{i});
            if exist(fullFilename, 'file')
                uiradiobutton(colorGrp, 'Text', extensions{i}, ...
                    'Position', [10, positionY, 50, 20]);
                positionY = positionY - 25;
            end
        end
    end

    function renameGrps(~, ~)
        groupIds = rendererTable.grpColors{activeIdx}.keys;

        renameFig = figure('Name', 'Rename Groups', 'Position', [500, 500, 300, 400], ...
            'Scrollable', 'on', 'NumberTitle', 'off', 'MenuBar','none');

        % Old Group ID label and dropdown
        uicontrol(renameFig, 'Style', 'text', 'String', 'Old Group ID:', 'Position', [30, 370, 100, 22], 'HorizontalAlignment', 'left');
        oldGrpId = uicontrol(renameFig, 'Style', 'popupmenu', 'String', string(groupIds), 'Position', [135, 370, 150, 22]);
    
        % OR label
        uicontrol(renameFig, 'Style', 'text', 'String', '(OR)', 'Position', [140, 340, 100, 22], 'HorizontalAlignment', 'left');
    
        % Face indices label and textarea
        uicontrol(renameFig, 'Style', 'text', 'String', 'Face Indices:', 'Position', [30, 310, 100, 22], 'HorizontalAlignment', 'left');
        faceIndices = uicontrol(renameFig, 'Style', 'edit', 'Position', [30, 150, 255, 130], 'HorizontalAlignment', 'left', 'Max', 2);
        uicontrol(renameFig, 'Style', 'text', 'String', 'Enter comma-separated face indices (overrides old ID)', ...
         'Position', [30, 285, 255, 20], 'FontSize', 8, 'FontAngle', 'italic', 'ForegroundColor', [0.5, 0.5, 0.5], 'HorizontalAlignment', 'left');

        % New Group ID label and text field
        uicontrol(renameFig, 'Style', 'text', 'String', 'New Group ID:', 'Position', [30, 110, 100, 22], 'HorizontalAlignment', 'left');
        newGrpId = uicontrol(renameFig, 'Style', 'edit', 'Position', [135, 110, 150, 22]);

        % Apply and Cancel buttons
         uicontrol(renameFig, 'Style', 'pushbutton', 'String', 'Apply', ...
            'Position', [80, 70, 80, 30], 'Callback', @applyRenameCb);
         uicontrol(renameFig, 'Style', 'pushbutton', 'String', 'Cancel', ...
            'Position', [180, 70, 80, 30], 'Callback', @(~, ~) close(renameFig));

        function applyRenameCb(~, ~)
            oldId = str2double(oldGrpId.String(oldGrpId.Value));
            newId = str2double(newGrpId.String);

            faceSelections = [];
            if ~isempty(faceIndices.String)
                input_str = strrep(faceIndices.String, ' ', '');  % Remove whitespace
                faceIndicesStr = strsplit(input_str, ',');  % Split by comma
                if ~isempty(faceIndicesStr{1})
                    faceSelections = str2double(faceIndicesStr);
                    faceSelections = faceSelections(~isnan(faceSelections));
                end    
            end
    
            if isempty(faceSelections)
                faceSelections = find(activeNwk.faceMx(:, 1) == oldId);
            end
    
            activeNwk.faceMx(faceSelections, 1) = newId;
            rendererTable.nwkObj{activeIdx} = activeNwk;
            initGroupBox();
            faceGrpEditCb();
    
            close(renameFig);
        end
    end

    function color = getObjColorName(grpColorDict)

        validColors = {'red', 'blue', 'green', 'cyan', 'magenta', 'yellow', 'black'};

        solidColor = true;
        color = '';
        if ~isempty(grpColorDict)
            firstColor = grpColorDict.values{1};
            for j = 2:length(grpColorDict.keys)
                if ~isequal(grpColorDict.values{j}, firstColor)
                    solidColor = false;
                    break;
                end
            end

            if solidColor
               predefinedRGB = validatecolor(validColors, 'multiple');
               matchIdx = find(all(predefinedRGB == firstColor, 2));
               if ~isempty(matchIdx)
                  color = validColors{matchIdx}; 
               end
            end
        end

        % When existing single solid color is not one of predefined color names
        % or When groups have different colors - assign a random color name from valid names
        if isempty(color) 
            idx = randi([1, 7]);
            color = validColors{idx};
        end
    end

    function dynamicGrouping()
        meanDia = mean(activeNwk.dia);
        stdDevDia = std(activeNwk.dia);

        limit1 = meanDia - stdDevDia;
        limit2 = meanDia + stdDevDia;

        numRows = size(activeNwk.faceMx, 1);
        groupIds = zeros(numRows, 1);

        firstInterval = activeNwk.dia < limit1;
        secondInterval = activeNwk.dia >= limit1 & activeNwk.dia < limit2;
        thirdInterval = activeNwk.dia >= limit2;

        % If no values are below limit1, adjust the intervals
        if all(~firstInterval)
            firstInterval = activeNwk.dia < meanDia;
            secondInterval = activeNwk.dia >= meanDia & activeNwk.dia < limit2;
        end

        % If no values are above limit2, adjust the intervals
        if all(~thirdInterval)
            thirdInterval = activeNwk.dia >= meanDia;
            secondInterval = activeNwk.dia < meanDia & activeNwk.dia >= limit1;
        end

        groupIds(firstInterval) = -1;
        groupIds(secondInterval) = -2;
        groupIds(thirdInterval) = -3;
        activeNwk.faceMx(:, 1) = groupIds;

        rendererTable.nwkObj{activeIdx} = activeNwk;
    end

    function faceProp = extractFaceProp()

        selectedIdx = find([colorGrp.Children.Value] == 1);
        selectedText = colorGrp.Children(selectedIdx).Text;

        if strcmp(selectedText, 'grp') || strcmp(selectedText, 'dia')
            faceProp = activeNwk.dia;
        else
         
            baseFilename = rendererTable.fileName{activeIdx};
            [path, name, ~] = fileparts(baseFilename);
            baseFilename = fullfile(path, name);
            fullFilename = strcat(baseFilename, '.', selectedText);
    
            fileID = fopen(fullFilename, 'r');
            faceProp = textscan(fileID, '%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true); 
            fclose(fileID);
            faceProp = faceProp{1};
        end
    end

    function addColorbar(propValues)
        cbar = colorbar;
        eps = 0;
        if min(propValues) == max(propValues)
            eps = 0.1;
        end
        clim([min(propValues)-eps max(propValues)+eps]);
        cbar.Ticks = linspace(min(propValues)-eps, max(propValues)+eps, 10);
        cbar.TickLabels = arrayfun(@num2str, linspace(min(propValues)-eps, max(propValues)+eps, 10), 'UniformOutput', false);
    end 

    function checkedGroupIDs = findCheckedGrpIds()
        checkedGroupIDs = [];
        for i = 1:size(tableGrpBoxes, 1)
             if tableGrpBoxes.grpBoxHandles{i}.Value
                 groupID = str2double(tableGrpBoxes.grpBoxHandles{i}.Text);
                 checkedGroupIDs = [checkedGroupIDs, groupID];
             end
         end
    end

    function tabChangeCb(~, event)
        % Uncheck the buttons, recolor the graph, disable dcm mode
        if ~strcmp(event.NewValue.Title, pathTab.Title)
            shortestPathSelect.Value = false;
            connectedComp.Value = false;
            
            if (~isempty(activeHandle))
                reColorGrps(); % color based on property?
                set(activeHandle, 'NodeColor', nodeColor, 'LineWidth', 2, 'MarkerSize', 2); % what if active file is changed?
            end

            dcm_obj = datacursormode(axesFig);
            set(dcm_obj, 'Enable', 'off', 'UpdateFcn', []);

            twoPts4MultiSelect = []; multiSelectFaceIdx = []; multiSelect.Value = 0;
            set([selectedFaces,groupIdBox], 'String', '');            
        end
    end    
 
    function faceZoomCb(~, ~)
        zoomFig = figure('Name', 'Face Zoom View', 'Position', [300 300 800 400], 'Resize', 'on', ...
                         'Visible', 'off', 'SizeChangedFcn', @resizeFaceZoom, 'NumberTitle', 'off', ...
                         'CloseRequestFcn', @onCloseZoomFig);
        
        expandPathState = [];
        setappdata(zoomFig, 'expandPathState', expandPathState);
        expandChildState = [];
        setappdata(zoomFig, 'expandChildState', expandChildState);
                     
        buttonNames = {'Labels', 'Directions', 'Reset Zoom', 'Toggle Cylinders', 'Expand Path', 'Expand Children'};
        buttonWidths = [60, 80, 80, 130, 100, 120];
        buttonCallbacks = {@labelsFaceZoomCb, @DirectionsFaceZoomCb, @ResetFaceZoomCb, ...
                    @cylindersFaceZoomCb, @ExpandPathFaceZoomCb, @ExpandChildrenFaceZoomCb };

        spacing = 10; margin = 10; buttonPanelHeight = 40;
        totalWidth = sum(buttonWidths) + spacing*(numel(buttonNames)-1);

        % Get figure position and create the button panel.
        figPos = get(zoomFig, 'Position');
        buttonPanel = uipanel(zoomFig, 'Units', 'pixels', ...
                              'Position', [margin, figPos(4)-margin-buttonPanelHeight, totalWidth, buttonPanelHeight], ...
                              'BorderType', 'none');
    
        % Loop over the arrays to create each button.
        xPos = 0; buttonHandles = gobjects(1, length(buttonNames));
        for i = 1:length(buttonNames)
            buttonHandles(i) = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', buttonNames{i}, ...
                      'Units', 'pixels', 'Position', [xPos, 0, buttonWidths(i), buttonPanelHeight], ...
                      'Callback', buttonCallbacks{i});
            xPos = xPos + buttonWidths(i) + spacing;
        end

        % Create the blank panel that will contain the axes.
        blankPanel = uipanel(zoomFig, 'Units', 'pixels', ...
                             'Position', [margin, margin, figPos(3)-2*margin, figPos(4)-buttonPanelHeight-2*margin], ...
                             'BackgroundColor', [1 1 1]);
    
        % Create an axes inside the blank panel.
        axFaceZoom = axes('Parent', blankPanel, 'Units', 'normalized', 'Position', [0 0 1 1], 'Color', [1 1 1]);
        axis(axFaceZoom, 'off');

        % Get faces list, and the first one of them
        faceZoomList = faceEditCb();
        if isempty(faceZoomList)
            firstFaceIdx = 1;
        else
            firstFaceIdx = faceZoomList(1);
        end

        if ~isempty(activeNwk)
            fZoomG = graph(activeNwk.faceMx(:,2), activeNwk.faceMx(:,3), 1:activeNwk.nf);
            type = 'graph';
            fZoomG.Nodes = table(activeNwk.ptCoordMx(:,1), activeNwk.ptCoordMx(:,2), activeNwk.ptCoordMx(:,3), ...
                    'VariableNames', {'X','Y','Z'});
            fZoomG.Nodes.Labels(:) = 1:activeNwk.np;
        
            hold(axFaceZoom, 'on');
            faceZoomHandle = plot(fZoomG, 'XData', fZoomG.Nodes.X, 'YData', fZoomG.Nodes.Y, 'ZData', fZoomG.Nodes.Z, ...
                'NodeColor', nodeColor, 'EdgeColor', [0 0 0.5], 'NodeLabel', {}, ...
                'MarkerSize', 2, 'LineWidth', 2, 'Parent', axFaceZoom);
            hold(axFaceZoom, 'off');
            faceZoomHandle.UserData = struct('type', type, 'selections', {}, 'groups', []);
            faceEdgeIdx = find(fZoomG.Edges.Weight == firstFaceIdx);
            highlight(faceZoomHandle, fZoomG.Edges.EndNodes(faceEdgeIdx,1), fZoomG.Edges.EndNodes(faceEdgeIdx,2), ...
                        'EdgeColor', 'green', 'LineWidth', 4);

            set(buttonHandles(strcmp(buttonNames, 'Expand Path')), 'Callback', ...
                @(src, evt) expandPathZoomCb(src, evt, zoomFig, faceZoomHandle, firstFaceIdx, []));
            set(buttonHandles(strcmp(buttonNames, 'Expand Children')), 'Callback', ...
                 @(src, evt) expandChildrenZoomCb(src, evt, zoomFig, faceZoomHandle, firstFaceIdx, []));



            endNodes = fZoomG.Edges.EndNodes(faceEdgeIdx, :);
            pt1 = [fZoomG.Nodes.X(endNodes(1)), fZoomG.Nodes.Y(endNodes(1)), fZoomG.Nodes.Z(endNodes(1))];
            pt2 = [fZoomG.Nodes.X(endNodes(2)), fZoomG.Nodes.Y(endNodes(2)), fZoomG.Nodes.Z(endNodes(2))];
            midpoint = (pt1 + pt2) / 2;
            faceSize = norm(pt1 - pt2); camOffset = 0.7 * faceSize;
            
            camPos = midpoint + [0, 0, camOffset]; % Set CameraPosition along Z direction
            set(axFaceZoom, 'CameraTarget', midpoint, 'CameraPosition', camPos); %, 'CameraViewAngle', 10);
        end

        set(zoomFig, 'Visible', 'on');
        set(axFaceZoom, 'WindowScrollWheelFcn', @(~, evt) axScrollZoomCb(evt, axFaceZoom));
    
        function resizeFaceZoom(src, ~)
             figPos = get(src, 'Position');
             set(buttonPanel, 'Position', [margin, figPos(4)-margin-buttonPanelHeight, totalWidth, buttonPanelHeight]);
             set(blankPanel, 'Position', [margin, margin, figPos(3)-2*margin, figPos(4)-buttonPanelHeight-2*margin]);
        end
    end

    function ptZoomCb(~, ~)
        zoomFig = figure('Name', 'Point Zoom View', 'Position', [300 300 800 400], 'Resize', 'on', ...
                         'Visible', 'off', 'SizeChangedFcn', @resizeFaceZoom, 'NumberTitle', 'off', ...
                         'CloseRequestFcn', @onCloseZoomFig);
        
        expandPathState = []; setappdata(zoomFig, 'expandPathState', expandPathState);
        expandChildState = []; setappdata(zoomFig, 'expandChildState', expandChildState);
                     
        buttonNames = {'Labels', 'Directions', 'Reset Zoom', 'Toggle Cylinders', 'Expand Path', 'Expand Children'};
        buttonWidths = [60, 80, 80, 130, 100, 120];
        buttonCallbacks = {@labelsFaceZoomCb, @DirectionsFaceZoomCb, @ResetFaceZoomCb, ...
                    @cylindersFaceZoomCb, @expandPathZoomCb, @expandChildrenZoomCb };

        spacing = 10; margin = 10; buttonPanelHeight = 40;
        totalWidth = sum(buttonWidths) + spacing*(numel(buttonNames)-1);

        % Get figure position and create the button panel.
        figPos = get(zoomFig, 'Position');
        buttonPanel = uipanel(zoomFig, 'Units', 'pixels', ...
                              'Position', [margin, figPos(4)-margin-buttonPanelHeight, totalWidth, buttonPanelHeight], ...
                              'BorderType', 'none');
    
        % Loop over the arrays to create each button.
        xPos = 0; buttonHandles = gobjects(1, length(buttonNames));
        for i = 1:length(buttonNames)
            buttonHandles(i) = uicontrol(buttonPanel, 'Style', 'pushbutton', 'String', buttonNames{i}, ...
                      'Units', 'pixels', 'Position', [xPos, 0, buttonWidths(i), buttonPanelHeight], ...
                      'Callback', buttonCallbacks{i});
            xPos = xPos + buttonWidths(i) + spacing;
        end

        % Create the blank panel that will contain the axes, create an axes inside the blank panel.
        blankPanel = uipanel(zoomFig, 'Units', 'pixels', ...
                             'Position', [margin, margin, figPos(3)-2*margin, figPos(4)-buttonPanelHeight-2*margin], ...
                             'BackgroundColor', [1 1 1]);
        axPtZoom = axes('Parent', blankPanel, 'Units', 'normalized', 'Position', [0 0 1 1], 'Color', [1 1 1]);
        axis(axPtZoom, 'off');

        % Get faces list, and the first one of them
        ptZoomList = ptEditCb();
        if isempty(ptZoomList)
            firstPtIdx = 1;
        else
            firstPtIdx = ptZoomList(1);
        end

        if ~isempty(activeNwk)
            ptZoomG = graph(activeNwk.faceMx(:,2), activeNwk.faceMx(:,3), 1:activeNwk.nf);
            type = 'graph';
            ptZoomG.Nodes = table(activeNwk.ptCoordMx(:,1), activeNwk.ptCoordMx(:,2), activeNwk.ptCoordMx(:,3), ...
                    'VariableNames', {'X','Y','Z'});
            ptZoomG.Nodes.Labels(:) = 1:activeNwk.np;
        
            hold(axPtZoom, 'on');
            ptZoomHandle = plot(ptZoomG, 'XData', ptZoomG.Nodes.X, 'YData', ptZoomG.Nodes.Y, 'ZData', ptZoomG.Nodes.Z, ...
                'NodeColor', nodeColor, 'EdgeColor', [0 0 0.5], 'NodeLabel', {}, ...
                'MarkerSize', 2, 'LineWidth', 2, 'Parent', axPtZoom);
            hold(axPtZoom, 'off');
            ptZoomHandle.UserData = struct('type', type, 'selections', {}, 'groups', []);
            ptIdx = find(ptZoomG.Nodes.Labels == firstPtIdx);
            highlight(ptZoomHandle, ptIdx, 'NodeColor', nodeColor, 'MarkerSize', 2);

            set(buttonHandles(strcmp(buttonNames, 'Expand Path')), 'Callback', ...
                @(src, evt) expandPathZoomCb(src, evt, zoomFig, ptZoomHandle, [], firstPtIdx));
            set(buttonHandles(strcmp(buttonNames, 'Expand Children')), 'Callback', ...
                 @(src, evt) expandChildrenZoomCb(src, evt, zoomFig, ptZoomHandle, [], firstPtIdx));
        end

        set(zoomFig, 'Visible', 'on');
    
        function resizeFaceZoom(src, ~)
             figPos = get(src, 'Position');
             set(buttonPanel, 'Position', [margin, figPos(4)-margin-buttonPanelHeight, totalWidth, buttonPanelHeight]);
             set(blankPanel, 'Position', [margin, margin, figPos(3)-2*margin, figPos(4)-buttonPanelHeight-2*margin]);
        end
    end

    function expandChildrenZoomCb(~, ~, zoomFig, zoomHandle, firstFaceIdx, firstPtIdx)
        stateVar = getappdata(zoomFig, 'expandChildState');
        if isempty(stateVar)
            stateVar.C1 = nwkHelp.ConnectivityMx(activeNwk);
            stateVar.C2 = stateVar.C1';

            stateVar.visitedPts = containers.Map(num2cell(1:activeNwk.np), num2cell(false(1, activeNwk.np)));
            stateVar.visitedFaces = containers.Map(num2cell(1:activeNwk.nf), num2cell(false(1, activeNwk.nf)));

            if (~isempty(firstFaceIdx))
                stateVar.visitedFaces(firstFaceIdx) = true;
                for p = activeNwk.faceMx(firstFaceIdx,2:3), stateVar.visitedPts(p) = true; end
                stateVar.currentPts = activeNwk.faceMx(firstFaceIdx,3);
            elseif (~isempty(firstPtIdx))
                stateVar.visitedPts(firstPtIdx) = true;
                stateVar.currentPts = firstPtIdx;
            end

        end

        [ptsDown, facesDown] = nwkHelp.findDownPtsAndFaces(stateVar.currentPts, stateVar.C1, stateVar.C2);
        newPts = unique(ptsDown); newFaces = unique(facesDown);

        % Remove already visited
        newPts = newPts(~cellfun(@(x) x, values(stateVar.visitedPts, num2cell(newPts))));
        newFaces = newFaces(~cellfun(@(x) x, values(stateVar.visitedFaces, num2cell(newFaces))));

        % Book keeping, Mark new points and faces as visited, reset current points
        if isempty(newFaces)
            disp('No new faces to expand.'); return;
        end

        for p = newPts'
            stateVar.visitedPts(p) = true;
        end
        for f = newFaces'
            stateVar.visitedFaces(f) = true;
        end
        stateVar.currentPts = newPts;

        % Highlight faces
        if ~isempty(newFaces)
            highlight(zoomHandle, activeNwk.faceMx(newFaces, 2), activeNwk.faceMx(newFaces, 3), ...
                'EdgeColor', 'green', 'LineWidth', 4);
        end
        
        setappdata(zoomFig, 'expandChildState', stateVar);
    end

    function expandPathZoomCb(~, ~, zoomFig, zoomHandle, firstFaceIdx, firstPtIdx)
        stateVar = getappdata(zoomFig, 'expandPathState');
        if isempty(stateVar)
            stateVar.C1 = nwkHelp.ConnectivityMx(activeNwk);
            stateVar.C2 = stateVar.C1';

            stateVar.visitedPts = containers.Map(num2cell(1:activeNwk.np), num2cell(false(1, activeNwk.np)));
            stateVar.visitedFaces = containers.Map(num2cell(1:activeNwk.nf), num2cell(false(1, activeNwk.nf)));

            if (~isempty(firstFaceIdx))
                stateVar.visitedFaces(firstFaceIdx) = true;
                for p = activeNwk.faceMx(firstFaceIdx,2:3), stateVar.visitedPts(p) = true; end
                stateVar.currentPts = activeNwk.faceMx(firstFaceIdx,2:3);
            elseif (~isempty(firstPtIdx))
                stateVar.visitedPts(firstPtIdx) = true;
                stateVar.currentPts = firstPtIdx;
            end
        end

        [ptsUp, facesUp] = nwkHelp.findUpPtsAndFaces(stateVar.currentPts, stateVar.C1, stateVar.C2);
        [ptsDown, facesDown] = nwkHelp.findDownPtsAndFaces(stateVar.currentPts, stateVar.C1, stateVar.C2);
        newPts = unique([ptsUp; ptsDown]); newFaces = unique([facesUp; facesDown]);

        % Remove already visited
        newPts = newPts(~cellfun(@(x) x, values(stateVar.visitedPts, num2cell(newPts))));
        newFaces = newFaces(~cellfun(@(x) x, values(stateVar.visitedFaces, num2cell(newFaces))));

        % Book keeping, Mark new points and faces as visited, reset current points
        if isempty(newFaces)
            disp('No new faces to expand.'); return;
        end

        for p = newPts'
            stateVar.visitedPts(p) = true;
        end
        for f = newFaces'
            stateVar.visitedFaces(f) = true;
        end
        stateVar.currentPts = newPts;

        % Highlight faces
        if ~isempty(newFaces)
            highlight(zoomHandle, activeNwk.faceMx(newFaces, 2), ...
                activeNwk.faceMx(newFaces, 3), 'EdgeColor', 'green', 'LineWidth', 4);
        end
        
        setappdata(zoomFig, 'expandPathState', stateVar);
    end

    function onCloseZoomFig(src, ~)
        if isappdata(src, 'expandPathState')
            rmappdata(src, 'expandPathState');
        end
        if isappdata(src, 'expandChildState')
            rmappdata(src, 'expandChildState');
        end
        delete(src);
    end

    function axScrollZoomCb(~, event, axZoom)
        zoomFactor = 0.1;  % Adjust how fast zooming happens
        scrollDist = event.VerticalScrollCount; axZoom.Pointer = 'watch';
    
        camPos = get(axZoom, 'CameraPosition'); camTarget = get(axZoom, 'CameraTarget');
        newCamPos = camPos - scrollDist * zoomFactor * (camPos - camTarget);

        newZoomDist = norm(newCamPos - camTarget);
        if newZoomDist >= minZoomDist && newZoomDist <= maxZoomDist
            set(axZoom, 'CameraViewAngleMode', 'manual', 'CameraPosition', newCamPos);
        end
        axZoom.Pointer = 'arrow';
    end

    function andOrCb(~, ~)
      if strcmp(andOrBtn.Text, 'AND')
        andOrBtn.Text = 'OR';
        andOrBtn.Tooltip = sprintf('Gives faces, points that are a Intersection\nof faceEdit and ptEdit conditions');
      else
        andOrBtn.Text = 'AND';
        andOrBtn.Tooltip = sprintf('Gives faces, points that are a Union\nof faceEdit and ptEdit conditions');
      end
      updateSelections();
    end

    function updateActivePlot()

        fig.Pointer = 'watch'; axesFig.Pointer = 'watch';
        type = 'subgraph';
        if (directionsOn.Value); type = 'disubgraph'; end

        hold(ax, "on");
        if ~isempty(rendererTable.plotHandle{activeIdx})
            delete(rendererTable.plotHandle{activeIdx});
        end
        
        if ~isempty(activeG.Nodes)
            activeHandle = plot(ax, activeG, 'XData', activeG.Nodes.X, 'YData', activeG.Nodes.Y, 'ZData', activeG.Nodes.Z, ...
                 'NodeColor', nodeColor, 'EdgeColor', 'k', 'NodeLabel', {}, 'MarkerSize', 2, 'LineWidth', 2) ;
            activeHandle.UserData = struct('type', '', 'selections', {}, 'groups', []);         
            activeHandle.UserData(1).type = type;

            rendererTable{activeIdx, 4} = {activeHandle};
            if labelsOn.Value
                labelsOnCb();
            end
        end

        hold(ax, "off");
        
        resetOnRedraw();
        drawnow;
        fig.Pointer = 'arrow'; axesFig.Pointer = 'arrow';
    end    

end
