classdef nwkHelp
    % static collection of procedures to computer useful nwk properties
    % Lin 4/18/2022
    % interface the property into class-style access
    % allows us to put procedures together in a single file

    % LV 23/10/2024 added nwkx binary load and save
    % a test function to display usage of nwkx binary load and save
    properties
        %nwk
    end
    
    methods
        function self = nwkHelp() % not really needed
            %UNTITLED3 Construct an instance of this class
            self;
        end       
    end
     methods (Static)
            % use as constructor
            function [nwk]=load(nwkFilename);
                if isfile([nwkFilename, '.nwkx']) 
                    [nwk]=binaryCaseReaderLV([nwkFilename, '.nwkx']);
                else
                    [nwk.faceMx,nwk.ptCoordMx,nwk.grpMx,nwk.dia,nwk.BC,nwk.np,nwk.nf,nwk.nt]=caseReaderAL(nwkFilename);
                end
                createPngForNwk(nwkFilename, nwk);
            end;
            function save(nwkFilename, nwk, type);
                if nargin < 3 , type = ''; end % Check if ext is provided
                if strcmp(type, 'nwkx')
                    binaryCaseWriterLV(nwkFilename, nwk);
                else    
                    caseWriterAL(nwkFilename, nwk);
                end
            end;
            % C1 is equal to the negative of the signed incidence Mx (-C2)
            function C1= ConnectivityMx(nwk); C1= ConnectivityMx2(nwk); end;
            function AA =AdjacencyMx(nwk); AA=makeAdjacencyMx_V2(nwk);end;
            % don't use any more    ---- makr for delete
            function [subnwk]=getSubNWK(nwk, faceSelection); [subnwk]=getSubNWK(nwk, faceSelection); end
            function [subnwk]=getSubNWKbyPts(nwk, ptSelection); [subnwk]=getSubNWKbyPts(nwk, ptSelection); end  
            function [fusednwk]=mergeNWKs(nwk1, nwk2);
                     [fusednwk]=mergeNWKs(nwk1, nwk2);           
            end 
            % Lin 2/1/2024 ---- new subnwkl procedure
            function [subnwk, sub2fullPtIdx, full2SubPtIdx]=getSubNWKAndPtIdx(nwk, faceSelection); 
                     [subnwk, sub2fullPtIdx, full2SubPtIdx]=getSubNWKAndPtIdx(nwk, faceSelection); 
            end   
            function [subnwk, sub2fullPtIdx, full2SubPtIdx, faceSelection]=getSubNWKAndPtIdxByPts(nwk, ptSelection); 
                     [subnwk, sub2fullPtIdx, full2SubPtIdx, faceSelection]=getSubNWKAndPtIdxByPts(nwk, ptSelection);
            end;    
            function [subnwk, sub2fullPtIdx, full2SubPtIdx, faceSelection]=getSubNWK_byMatlab(nwk, ptSelection); 
                     [subnwk, sub2fullPtIdx, full2SubPtIdx, faceSelection]=getSubNWK_byMatlab(nwk, ptSelection);
            end;   
            %
            function [inFlowPorts, outFlowPorts]=findBoundaryNodes(nwk);
                    [inFlowPorts, outFlowPorts]=findBoundaryNodes(nwk);            
            end
            function [inFlowFaces, outFlowFaces]=findBoundaryFaces(m);
                [inFlowFaces, outFlowFaces]=findBoundaryFaces(m); 
            end    
            function [indegree, outdegree] = getNodeDegrees(nwk, C1);
                     [indegree, outdegree] = getNodeDegrees(nwk, C1);
            end
            %%% Lin 10/30/2023
            %%%% idx=(indegree==1 & outdegree==2); % logical vectors showing true for bifurcations
            function [rootPt,rootF]= findRootPtAndFace(nwk, grpId);
                [rootPt,rootF]= findRootPtAndFace(nwk, grpId);
             end
            function [path, label]=findSurfacePathToHighestPressure(cn,pp, faceMx,ptCoordMx,  np, nf, nt, ff, C1, C2,  label)
                   [path, label]=findSurfacePathToHighestPressure(cn,pp, faceMx,ptCoordMx,  np, nf, nt, ff, C1, C2,  label);
             end    
             function [closestPtsIdx] = findClosePts(ptCoordMx, myPtSelection);
                      [closestPtsIdx] = findClosePts(ptCoordMx, myPtSelection);  
             end
             function [pts]= findConnectedPts(cn, C1, C2)
                  [pts]= findConnectedPts(cn, C1, C2);
             end;  
             function [pts, faces]= findUpPtsAndFaces(aP, C1, C2) % Lin 11/20/23
                      [pts, faces]= xxx_findUpPtsAndFaces(aP, C1, C2);
             end;         
             function [pts, faces]= findDownPtsAndFaces(aP, C1, C2)
                      [pts, faces]= xxx_findDownPtsAndFaces(aP, C1, C2);
             end;        
             function facePath=getFacesForPath(pathj, C1);
                  facePath=getFacesForPath(pathj, C1);
             end; 
             function C = getFaceCenter(aF, faceMx, ptCoordMx)
                 C = getFaceCenter(aF, faceMx, ptCoordMx);
             end; 
             % Lin 3/9/2024 --- this procedure seems flawed 
             % does not give face center, but face as vector
%              function faceCenterMx = getAllFaceCenters(nwk)
%                       faceCenterMx = nwk.ptCoordMx(nwk.faceMx(:,2),:) - nwk.ptCoordMx(nwk.faceMx(:,3),:);
%              end;   
              % Lin 5/14/2024 --- corrected version
              function faceCenterMx = getAllFaceCenters(nwk)
                       faceCenterMx = 0.5*(nwk.ptCoordMx(nwk.faceMx(:,2),:) + nwk.ptCoordMx(nwk.faceMx(:,3),:));
              end;   
             function C = getTriangleCenter(TIdx, ptCoordMx)
                  C = getTriangleCenter(TIdx, ptCoordMx);
             end;   
             % Lin 4/29/2024 --- we need to return entire nwk
             function nwk = flipFace(nwk,aF)
                      tmp = nwk.faceMx(aF,2); nwk.faceMx(aF,2)= nwk.faceMx(aF,3); nwk.faceMx(aF,3) = tmp;
             end; 
             function [ptIdx]= findPtIdx(nwk, aP)
                  [ptIdx]= findPtIdx(nwk, aP);
             end;  
             function nwk = renameGrp(nwk, oldGrpId, newGrpId)
                  nwk = renameGrp(nwk, oldGrpId, newGrpId)
             end
             % basic properties
             function Vf = getFaceVolumes(nwk)
                      l= vecnorm((nwk.ptCoordMx(nwk.faceMx(:,2),:)-nwk.ptCoordMx(nwk.faceMx(:,3),:)),2,2);
                      Vf = pi*nwk.dia.^2.*l;
             end    
             function Af = getFaceSurfaceArea(nwk)
                      l= vecnorm((nwk.ptCoordMx(nwk.faceMx(:,2),:)-nwk.ptCoordMx(nwk.faceMx(:,3),:)),2,2);
                      Af = pi*nwk.dia.*l;
             end  
             function CrossA = getCrossArea(nwk)
                      CrossA = pi/4*nwk.dia.^2;
             end   
             function ll = getFaceLengths(nwk)
                ll = vecnorm((nwk.ptCoordMx(nwk.faceMx(:,2),:)-nwk.ptCoordMx(nwk.faceMx(:,3),:)),2,2);
             end;
             function ll = getOneFaceLength(nwk, aF)
                ll = norm((nwk.ptCoordMx(nwk.faceMx(aF,2),:)-nwk.ptCoordMx(nwk.faceMx(aF,3),:)));
             end;
             function vel = getVelocity_mms(nwk, ff)
                      area = nwkHelp.getCrossArea(nwk);
                      vel=ff./area*1000/60; %[mm/s]
             end;
             function nwk = stretchFace(nwk,aF, finalLength);  
                    v = nwkHelp.getFaceAsVector(nwk, aF);
                    p1 = nwk.ptCoordMx(nwk.faceMx(aF,2),:);
                    p2New = p1 + finalLength*v/norm(v);
                    p2Idx = nwk.faceMx(aF,3);
                    nwk.ptCoordMx(p2Idx,1:3)=p2New; 
             end;  
             function v = getFaceAsVector(nwk, aF)
                   %v = (nwk.ptCoordMx(nwk.faceMx(aF,2),:)-nwk.ptCoordMx(nwk.faceMx(aF,3),:));
                   v = (nwk.ptCoordMx(nwk.faceMx(aF,3),:)-nwk.ptCoordMx(nwk.faceMx(aF,2),:))'; % Lin 4/1/24
             end;
             function nwk = setFaceInfo(nwk, aF, faceInfo)
                   nwk.faceMx(aF,1:length(faceInfo))= faceInfo;
             end;
             function Trf = getTrf(nwk, ff) % in seconds
                Vf  = nwkHelp.getFaceVolumes(nwk)/1000; % Convert from mm3 -> ml
                Trf = Vf./ff*60; % Convert min --> seconds
             end;
             function Trf = getTrfWithVf(nwk, ff, Vf) % in seconds
                %Vf  = nwkHelp.getFaceVolumes(nwk)/1000; % Convert from mm3 -> ml
                Trf = Vf./ff*60/1000; % Convert min --> seconds
             end;   
             function WSS = getWSS(nwk, ff, dia, MY) % in seconds  
                WSS = 32*MY/pi.*ff./(dia.^3); % Convert min --> seconds
                WSS = WSS*133.32e3;   % 1 [mmHg.min]*[mml/min]/[mm^3]-> N/m2
             end;
             function WorkLoss = getWorkLoss(nwk, ff, rr)   
                WorkLoss = ff.^2.*rr; % conv to {W] missing
                WorkLoss = 2.2e-6 * WorkLoss; % conv to [mmHg] -> [W] missing
             end;
             % useful distance functions
             function [ptIdx, dist] = getClosestPtIdx(nwk,aP)
                      [dist,ptIdx] = min(vecnorm(aP-nwk.ptCoordMx,2,2));
             end;     
             %
             function [aFIdx, dist] = getClosestFaceIdx(nwk,aP, faceCenterMx)
                      if isempty(faceCenterMx) 
                          faceCenterMx = nwkHelp.getAllFaceCenters(nwk); end;
                      %faceCenterMx = nwk.ptCoordMx(nwk.faceMx(:,2),:) - nwk.ptCoordMx(nwk.faceMx(:,3),:);
                      [dist,aFIdx] = min(vecnorm(aP-faceCenterMx,2,2));
             end;
             function testNwkxLoad(filename)
                 testNwkxLoad(filename);
             end;
             function createPngForNwk(filePath)
                 createPngForNwk(filePath);
             end;
     end   
end 
%% implementations
%% rewrite for more efficiency --- no loop; 
% see below getSubNWKAndPtIdx ---- do not use any more
function [subnwk]=getSubNWK(nwk, faceSelection); 
subFaceMx=nwk.faceMx(faceSelection,:);
pts=[subFaceMx(:,2);subFaceMx(:,3)];
%pts=find(subFaceMx(:,2)); pts=[find(subFaceMx(:,2));find(subFaceMx(:,3))];
pts=unique(pts); %
oldIdx=subFaceMx(1,2);newIdx = find(pts==oldIdx); % this requires search, but no data
% make new faceMx
nf=length(faceSelection);
% Lin this could be done without a loop
for i=1:nf;
    subFaceMx(i,2)=find(pts==subFaceMx(i,2));
    subFaceMx(i,3)=find(pts==subFaceMx(i,3));
end;    
subnwk.faceMx=subFaceMx;  
subnwk.ptCoordMx = nwk.ptCoordMx(pts, :);% make new ptMx
subnwk.dia = nwk.dia(faceSelection); % diameters
subnwk.nf=nf;subnwk.np=length(pts);subnwk.nt=subnwk.nf+subnwk.np;
end

function [subnwk]=getSubNWKbyPts(nwk, ptSelection); 
np=length(ptSelection);
[f1, ~]=find(nwk.faceMx(:,2)==ptSelection);
[f2, ~]=find(nwk.faceMx(:,3)==ptSelection);
faceSelection = unique([f1; f2]);
subnwk=getSubNWK(nwk, faceSelection); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Lin 2/1/2024 new subnetw procdures 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lin 5/5/2022 ---make subNWK using the subgraph features ---- 
% use to replace the above getSubNWK procedures????
% from ooPartionTerritories ---- not tested in this class conntext yet
function [aSubNWK, aTerritory]=makeSubNWKFromPtLabels(faceMx, ptCoordMx, dia, label, nodeId)
G = graph(faceMx(:,2), faceMx(:,3), dia);
ddd= G.Edges.Weight;% should be dd.
idx=find(label==nodeId);
%idxFeed=find(idx==feedlocation(4));
aTerritory = subgraph(G,idx);
aSubNWK.ptCoordMx = ptCoordMx(idx,:);
ptsIdx=table2array(aTerritory.Edges);
aSubNWK.np=length(idx);aSubNWK.nf=length(ptsIdx);aSubNWK.nt=aSubNWK.nf+aSubNWK.np;
aSubNWK.faceMx = zeros(aSubNWK.nf,5);
aSubNWK.faceMx(:,1)=nodeId;  % node ID also serves as label for the subNWK
% the ptsIdx contains the diameters alaos
aSubNWK.faceMx(:,2:3)=ptsIdx(:,1:2);
aSubNWK.dia = ptsIdx(:,3);
aSubNWK.dia=aTerritory.Edges.Weight;% should be dd.
end

%%%% Lin 6/7/2024 --- updqdate needed - this fails when faceMx dont ahve same Dimensons
function [fusedNwk]=mergeNWKs(nwk1, nwk2); 
fusedNwk.ptCoordMx=[nwk1.ptCoordMx; nwk2.ptCoordMx];
tempFaceMx=nwk2.faceMx;
tempFaceMx(:,2:3)=nwk2.faceMx(:,2:3)+nwk1.np;
fusedNwk.faceMx=[nwk1.faceMx; tempFaceMx];
fusedNwk.dia=[nwk1.dia; nwk2.dia];
fusedNwk.nf=nwk1.nf+nwk2.nf;fusedNwk.np=nwk1.np+nwk2.np;
fusedNwk.nt=fusedNwk.nf+fusedNwk.np;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Lin 2/1/2024 new subnetw procdures 
function [subnwk, sub2fullPtIdx, full2SubPtIdx]=getSubNWKAndPtIdx(nwk, faceSelection); 
nf=length(faceSelection);
subFaceMx=nwk.faceMx(faceSelection,:);
pts=[subFaceMx(:,2);subFaceMx(:,3)];
pts=unique(pts); %
np=length(pts);
%%%%%%%%%%%%%
sub2fullPtIdx=pts; % gives oldIdx for new idx, 
full2SubPtIdx=zeros(nwk.np,1);     % full gives newIddx for sub 
full2SubPtIdx(pts)=1:np;     % full gives newIddx for sub 
% make new faceMx
subFaceMx(:,2)=full2SubPtIdx(subFaceMx(:,2));
subFaceMx(:,3)=full2SubPtIdx(subFaceMx(:,3));
%    
subnwk.faceMx=subFaceMx;  
subnwk.ptCoordMx = nwk.ptCoordMx(pts, :);% make new ptMx
subnwk.dia = nwk.dia(faceSelection); % diameters
subnwk.nf=nf;subnwk.np=length(pts);subnwk.nt=subnwk.nf+subnwk.np;
end

% Lin 2/1/2024 ---- not tested 
% function [subnwk, sub2fullPtIdx, full2SubPtIdx]=getSubNWKAndPtIdxByPts(nwk, ptSelection); 
% [f1, ~]=find(nwk.faceMx(:,2)==ptSelection);
% [f2, ~]=find(nwk.faceMx(:,3)==ptSelection);
% faceSelection = unique([f1; f2]);
% [subnwk, sub2fullPtIdx, full2SubPtIdx]=getSubNWKAndPtIdx(nwk, faceSelection); 
% end

% Lin 2/28/2024 ----  tested 
function [subnwk, sub2fullPtIdx, full2SubPtIdx, faceSelection]=getSubNWKAndPtIdxByPts(nwk, ptSelection)
f1 = ismember(nwk.faceMx(:,2), ptSelection); % which faces have the enclosed spline pts
f2 = ismember(nwk.faceMx(:,3), ptSelection);
faceSelection = f1 | f2;
faceSelection = find(faceSelection); %conmvert logical to indixes
[subnwk, sub2fullPtIdx, full2SubPtIdx]=getSubNWKAndPtIdx(nwk, faceSelection); 
end

% % Lin 2/28/2024 ---- tested ---- downward flowing faces only
% function [subnwk, sub2fullPtIdx, full2SubPtIdx, faceSelection]=getSubNWKAndPtIdxByPts(nwk, ptSelection)
% f1 = ismember(nwk.faceMx(:,2), ptSelection); % which faces have the enclosed spline pts
% %f2 = ismember(nwk.faceMx(:,3), ptSelection);
% faceSelection = f1;
% faceSelection = find(faceSelection); %conmvert logical to indixes
% [subnwk, sub2fullPtIdx, full2SubPtIdx]=getSubNWKAndPtIdx(nwk, faceSelection); 
% end

function [subnwk, sub2fullPtIdx, full2SubPtIdx, faceSelection]=getSubNWK_byMatlab(nwk, ptSelection); 
dummyFaceIdx = 1:nwk.nf;
G = digraph(nwk.faceMx(:,2), nwk.faceMx(:,3), dummyFaceIdx);
face2graphIdx = G.Edges.Weight;
sG = subgraph(G, ptSelection);
% sub2fullPtIdx=ptSelection;                      % gives oldIdx for new idx, 
% full2SubPtIdx=zeros(nwk.np,1);               % full gives newIddx for sub 
% full2SubPtIdx(ptSelection)=1:length(ptSelection); 
faceSelection=sort(sG.Edges.Weight);
[subnwk, sub2fullPtIdx, full2SubPtIdx]=nwkHelp.getSubNWKAndPtIdx(nwk, faceSelection); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% C1 moved from nwkSim --- hould be used here
function C1= ConnectivityMx2(nwk)
    fi = [(1:nwk.nf)];nf=nwk.nf;np=nwk.np;
    p1 = nwk.faceMx(:,2)'; p2 = nwk.faceMx(:,3)'; % P1IDx   % P2 Idx
    C1=sparse([fi, fi], [p1, p2],[ones(1,nf), (-1)*ones(1,nf)],nf,np);
end
% % %     % TV 04/04/2024
% % %     % Make point to point adjacency matrix from face matrix
function AA = makeAdjacencyMx_V2(nwk)
    AA = sparse(nwk.faceMx(:,2),nwk.faceMx(:,3),1,nwk.np,nwk.np);
    AA = AA + AA';
end     




% % % Lin 3/18/2022 check this procedure to go the node with the highest pressure gradient
% % % grad dp = DeltaP/delta x
function [path, label]=findSurfacePathToHighestPressure(cn,pp, faceMx,ptCoordMx,  np, nf, nt, ff, C1, C2,  label)
    path=[cn];
    while (label(cn)==0)  && (length(path)<100)
    %while (label(cn)==0)  
        pts=findConnectedPts(cn,C1, C2);
        diffP=pp(pts);
        % distances
        dd=[];
        for i=1:length(diffP)
            diffP(i)=diffP(i)-pp(cn);
            di=ptCoordMx(pts(i),:)-ptCoordMx(cn,:);
            dd(i)=norm(di);
        end; 
        diffP1=diffP.*dd';
        [val1, idx1]=max(diffP1); % go to the node with the largest pressure
        diffP=diffP./dd';
        [val, idx]=max(diffP); % go to the node with the largest pressure
%         if idx~=idx1 
%             test = [pp(idx), pp(idx1), idx, idx1]   
%         end
        nextN=pts(idx);
        if label(nextN) ~= 0
          path=[path,nextN];
          % Lin 4/22/2022 --- label assignment needs to be checked
          grpId =label(nextN);
          label(path)=grpId;
          continue;
       else   
           path=[path, nextN];
           cn=nextN;
       end;
    end; 
end


function [pts]= findConnectedPts(cn, C1, C2)
        [iFaces,~]=find(C1(:,cn));
        [pts,~] =find(C2(:,iFaces)); % pts connected to faces 
        pts=setdiff(pts,cn);
end

%%%% Lin 12/6/2023 ===== This version scrambles faces and Pts 
% function [pts, faces]= xxx_findUpPtsAndFaces(aP, C1, C2)
%         [faces,~]=find(C1(:,aP)==-1);
%         [pts,~] =find(C2(:,faces)); % pts connected to faces  
%         pts=setdiff(pts,aP);
% end
%%%% Lin 12/6/2023 ===== This version scrambles faces and Pts 
% function [pts, faces]= xxx_findDownPtsAndFaces(aP, C1, C2)
%         [faces,~]=find(C1(:,aP)==1);
%         [pts,~] =find(C2(:,faces)); % pts connected to faces  
%         pts=setdiff(pts,aP);
% end
% corrected Lin 12/6/2023
function [pts, faces]= xxx_findUpPtsAndFaces(aP, C1, C2)
        [faces,~]=find(C1(:,aP)==-1);
        [pts, col ] = find(C2(:, faces)==1);
end
function [pts, faces]= xxx_findDownPtsAndFaces(aP, C1, C2)
        [faces,~]=find(C1(:,aP)==1);
        [pts, col ] = find(C2(:, faces)==-1);
end

function [closestPtsIdx] = findClosePts(ptCoordMx, myPtSelection);
closestPtsIdx=[];
n =length(myPtSelection(:,1));
 for i=1:n 
    p = myPtSelection(i, :); % take first point
    deltaPMx = ptCoordMx-p;
    l = vecnorm(deltaPMx'); % computer the norm kof each row
    [lnew,idx]=sort(l);
    closestPtsIdx = [closestPtsIdx; idx(1)];
 end  
closestPtsIdx=sort(unique(closestPtsIdx)); % sort and remov duoplicates
end

function [inFlowPorts, outFlowPorts]=findBoundaryNodes(m);
C1= nwkSim.ConnectivityMx(m.nf,m.np,m.faceMx); 
C1i=max(-C1,0); inFlowPorts = find(sum(C1i)==0);
C1o=max(C1,0); outFlowPorts = find(sum(C1o)==0);% some segments have nonbinary connections
C1a=abs(C1);
ptValence=sum(C1a);idx=find(ptValence==1);
inFlowPorts=intersect(inFlowPorts, idx); % true inputs 
outFlowPorts=intersect(outFlowPorts, idx); % true outputs
end

function [indegree, outdegree] = getNodeDegrees(nwk, C1);
e1f=ones(nwk.nf,1);
C1i=(max(-C1,0)); C1o=(max(C1,0)); 
indegree  = C1i'*e1f;
outdegree  = C1o'*e1f;
end

function [inFlowFaces, outFlowFaces]=findBoundaryFaces(m);
C1= nwkSim.ConnectivityMx(m.nf,m.np,m.faceMx); 
[inFlowPorts, outFlowPorts]=findBoundaryNodes(m);
for i=1:length(inFlowPorts)
    inFlowFaces(i) = find(C1(:,inFlowPorts(i)));
end; 
for i=1:length(outFlowPorts)
    outFlowFaces(i) = find(C1(:,outFlowPorts(i)));
end; 

end

% function facePath=getFacesForPath(pathj, C2);
% facePath=zeros(length(pathj)-1,1);
% for i=1:length(facePath)
%   [~,f1]= find(C2(pathj(i),:));
%   [~,f2]= find(C2(pathj(i+1),:));
%   facePath(i)=intersect(f1,f2);
% end
% end
% Lin 5/11/2022 --- rename getFacesForPtPath 
function facePath=getFacesForPath(pathj, C1);
facePath=zeros(length(pathj)-1,1);
for i=1:length(facePath)
  [f1,~]= find(C1(:,pathj(i)));
  [f2,~]= find(C1(:,pathj(i+1)));
  facePath(i)=intersect(f1,f2);
end
end

function C = getFaceCenter(aF, faceMx, ptCoordMx)
    pts=faceMx(aF,2:3);
    tpts=ptCoordMx(pts, :);
    C=sum(tpts)/2;
end

%Lin 5/4/2023 --- this function should be in nwk3Help
function C = getTriangleCenter(TIdx, ptCoordMx)
    tpts=ptCoordMx(TIdx, :);
    C=sum(tpts)/3;
end

function [ptIdx]= findPtIdx(nwk, aP)
ptIdx = find(nwk.ptCoordMx(:,1) == aP(1) & nwk.ptCoordMx(:,2) == aP(2) & nwk.ptCoordMx(:,3) == aP(3) );
end

function nwk = renameGrp(nwk, oldGrpId, newGrpId)
fidx=find(nwk.faceMx(:,1) == oldGrpId);
nwk.faceMx(fidx,1) = newGrpId;
end

% Lin 8/28/2022 add reader and write for completeness
function [faceMx,ptCoordMx,grpMx, dia,BC,np,nf,nt]=caseReaderAL(filename)
    myfileName = strcat(filename,'.fMx');
    faceMx = load(myfileName);
    myfileName = strcat(filename,'.pMx');
    ptCoordMx = load(myfileName);
    np= length(ptCoordMx(:,1));    nf= length(faceMx(:,2));   nt= np+nf;
    myfileName = strcat(filename,'.dia');
    if isfile(myfileName) dia = load(myfileName); 
    else dia=ones(nf,1); end 
    myfileName = strcat(filename,'.BC');
    if isfile(myfileName) BC = load(myfileName);
    else BC=[1 1 100; 100 1 0.1]; end    
    myfileName = strcat(filename,'.grpMx');
   if isfile(myfileName) grpMx = load(myfileName); 
   else grpMx=[];end    
end

function caseWriterAL(filename, nwk)
    if isfile([filename, '.fMx']) disp('warning file overwritten'); 
        [filename, '.fMx'] 
    end;
    ooSaveIntMx(nwk.faceMx, [filename, '.fMx']);
    pMx=nwk.ptCoordMx; save([filename, '.pMx'],'pMx', '-ascii');
    dia = nwk.dia; save([filename, '.dia'],'dia', '-ascii');   
end

function [nwk]=binaryCaseReaderLV(filename)
    nwk = load(filename, '-mat');
    nwk.np = length(nwk.ptCoordMx(:,1));
    nwk.nf = size(nwk.faceMx, 1);
    nwk.nt = nwk.np + nwk.nf;
    if isempty(nwk.BC)
        nwk.BC=[1 1 100; 100 1 0.1];
    end
end

function binaryCaseWriterLV(filename, nwk)
    saveFilename = [filename, '.nwkx'];
    if isfile(saveFilename)
        fprintf('warning: %s file overwritten', saveFilename);
    end
    fieldsToSave = {'ptCoordMx', 'faceMx', 'grpMx', 'dia', 'BC'};
    if size(nwk.ptCoordMx, 1) ~= nwk.np
        warning('nwk not consistent: ptCoordMx not consistent with np');
    end
    if size(nwk.faceMx, 1) ~= nwk.nf
        warning('nwk not consistent: faceMx not consistent with nf');
    end        
    if nwk.nt ~= (nwk.np + nwk.nf)
        warning('nwk not consistent: nt not consistent with np and nf');
    end
    save(saveFilename, '-struct', 'nwk', fieldsToSave{:}, '-v7.3');
end

function testNwkxLoad(filename)

    % load fMx, pMx, dia files into a matlab nwk structure variable
    nwk = nwkHelp.load(filename);

    % save the structure as a binary mat file with nwkx as file extension
    nwkHelp.save(filename, nwk, 'nwkx');
    
    % load from binary nwkx file into a matlab nwk structure variable 
    nwkBin = nwkHelp.load(filename);

    % check if both the structures are equal to ensure correctness
    isEqual = isequaln(nwk, nwkBin);

    if isEqual == 1
        disp('Saving nwkx file and loading from it has been successful');
    else
        disp('Saving nwkx file and loading from it has failed');
    end

end

% Create a small PNG file to be viewed as ico file
function createPngForNwk(filePath, nwk)
    [path, name, ext] = fileparts(filePath);
    pngName = fullfile(path, [name, ext, '.png']);

    if ~exist(pngName, 'file')
        tempFig = figure('Visible', 'off');
        set(tempFig, 'Position', [0, 0, 128, 128]);

        % on an ax axis, open the nwk as graph.
        ax = axes(tempFig); view(ax, 3); axis(ax, 'off');
        G = digraph(nwk.faceMx(:, 2), nwk.faceMx(:, 3));
        G.Nodes = table(nwk.ptCoordMx(:, 1), nwk.ptCoordMx(:, 2), nwk.ptCoordMx(:, 3), ...
           'VariableNames', {'X', 'Y', 'Z'});
        hold(ax, "on");
        plot(G, 'XData', G.Nodes.X, 'YData', G.Nodes.Y, 'ZData', G.Nodes.Z, 'NodeColor', '[0.2 0.2 0.2]', ...
            'EdgeColor', '[0 0 0.5]', 'NodeLabel', {}, 'EdgeLabel', {}, 'ShowArrows', 'off', ...
            'MarkerSize', 0.5, 'LineWidth', 0.5, 'Parent', ax);
        hold(ax, "off");

        frame = getframe(ax);
        imwrite(frame.cdata, pngName, 'png');
        
        close(tempFig);
        disp(['Created a PNG file for the loaded file: ', pngName]);
    end
end


function [rootPt,rootF]= findRootPtAndFace(nwk, grpId)
grpFaces=find(nwk.faceMx(:,1)==grpId); % faces In Grp
p1 = nwk.faceMx(grpFaces,2);
p2 = nwk.faceMx(grpFaces,3);
rootPt = setdiff(p1,p2);
if length(rootPt)>1 disp('Warning: should only have one root');end;
idx = find(nwk.faceMx(grpFaces,2)==rootPt(1)); % postion of face within grp
rootF=grpFaces(idx); % final faceIdx
end

% function [pList, fList]= xxx_getDownFacesAndPts(iFace, nwk, C1, C2)
%    aP1 = nwk.faceMx(iFace,2);   aP2 = nwk.faceMx(iFace,3);
%    pList = [aP1, aP2]; fList = [iFace];aF=iFace;
% while aF ~= 0 
%        aP2 = nwk.faceMx(aF,3);
% %       [upPts, downPts, upfaces, downfaces]= findConnectedPts(aP2,  nwk.faceMx);
%       [upPts, upfaces]= xxx_findUpPtsAndFaces(aP2, C1, C2);
%       [downPts, downfaces]= xxx_findDownPtsAndFaces(aP2, C1, C2);
%       %if length(downfaces)+length(upfaces) == 2
%       if length(downfaces)==1 & length(upfaces) == 1 
%         pList = [ pList, downPts(1)];
%         fList = [ fList, downfaces(1)];  
%         aF = downfaces(1);
%       else
%         aF=0;
%       end;  
% end      
% end
% 
% function [pList, fList]= xxx_getUpFacesAndPts(iFace, nwk, C1, C2)
%    aP1 = nwk.faceMx(iFace,2);   aP2 = nwk.faceMx(iFace,3);
%    pList = [aP2, aP1]; fList = [iFace];aF=iFace;
% while aF ~= 0 
%        aP1 = nwk.faceMx(aF,2);
%       %[upPts, downPts, upfaces, downfaces]= findConnectedPts(aP1,  nwk.faceMx);
%       [upPts, upfaces] = xxx_findUpPtsAndFaces(aP1, C1, C2);
%       [downPts, downfaces]= xxx_findDownPtsAndFaces(aP1, C1, C2);
%       %if length(downfaces)+length(upfaces) == 2 
%       if length(downfaces)==1 & length(upfaces) == 1 
%         pList = [ pList, upPts(1)];
%         fList = [ fList, upfaces(1)];  
%         aF = upfaces(1);
%       else
%         aF=0;
%       end;  
% end      
% end

% function [pts, faces]= xxx_findDownPtsAndFaces(aP, C1, C2)
%         [faces,~]=find(C1(:,aP)==1);
%         [pts,~] =find(C2(:,faces)); % pts connected to faces  
%         pts=setdiff(pts,aP);
% end
% 
% function [pts, faces]= xxx_findUpPtsAndFaces(aP, C1, C2)
%         [faces,~]=find(C1(:,aP)==-1);
%         [pts,~] =find(C2(:,faces)); % pts connected to faces  
%         pts=setdiff(pts,aP);
% end