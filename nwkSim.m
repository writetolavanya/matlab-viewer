classdef nwkSim
    % static class collection of procedures to simulate nwks
    % Lin 4/18/2022
    % interface the property into class-style access
    % allows us to put procedures together in a single file
    properties
        nwk
    end
    methods
        function self = nwkSim()
            %UNTITLED3 Construct an instance of this class
            self;
        end       
    end
    methods (Static)
            function test 
            disp('test');
            end
            % use as constructor
            function [s,ff, pp, ppAv, C1, feedLocations, patchSize]=setUpAndSolveHeatMapWithFeeds(filename, Npatches)
              %Npatches=50;
              %newpath = 'C:\andi\MatlabTests.V1\visualizationRoutines';userpath(newpath);
              [s.faceMx,s.ptCoordMx,s.grpMx,s.dia,s.BC,s.np,s.nf,s.nt]=caseReaderAL(filename);% should be nwk class
              [C1, alpha, D1, p, q, feedLocations, patchSize]=setUpHeatMapWithFeeds(s, Npatches);
              [ff, pp, ppAv] = nwkSim.solveReactiveFlow(C1, D1, p,q, alpha, s.nf, s.np,s.nt, s.dia,  patchSize);
            end
            function alpha= Resistance(ptCoordMx, faceMx, dia, nf )%mmHg.Min\ml
               alpha= Resistance(ptCoordMx, faceMx, dia, nf );%mm
            end
            % Lin 12/5/2022
            function alpha= Resistance_mm(ptCoordMx, faceMx, dia, nf )%mmHg.Min\ml
               alpha= Resistance_mm(ptCoordMx, faceMx, dia, nf );%mmHg.Min\ml
            end
            function alphainv= ResistanceInv(ptCoordMx, faceMx, dia, nf )
                alphainv= ResistanceInv(ptCoordMx, faceMx, dia, nf ); 
            end    
            function r= ResistanceVector(ptCoordMx, faceMx, dia, nf )%mmHg.Min\ml
                  r= ResistanceVector(ptCoordMx, faceMx, dia, nf );%mmHg.Min\ml
            end    
            % dimater free redcued Resistance --- needed in synthesis
            function r= DiameterFreeResistanceVector(nwk)%mmHg.Min\ml
                     r= DiameterFreeResistanceVector(nwk.ptCoordMx, nwk.faceMx, nwk.nf );%mmHg.Min\ml
            end  

             function r= ResistanceVector_mm(nwk)%mmHg.Min\ml
                     r= ResistanceVector_mm(nwk.ptCoordMx, nwk.faceMx, nwk.dia,nwk.nf );%mmHg.Min\ml
            end    
            % should args should be C1 = ConnectivityMx(nwk)
            function C1= ConnectivityMx(nf,np,faceMx) % should be in nwk class
               C1= ConnectivityMx2(nf,np,faceMx);
            end
            function [D1,p,q]= readFlowBC(BC, np, nf, nt)
                 [D1,p,q]= readFlowBC(BC, np, nf, nt)
            end;        
            function [ff, pp, ppAv] = solveReactiveFlow(C1, D1, p,q, Alpha, nf, np,nt, dia,  patchSize)
               [ff, pp, ppAv] = solveReactiveFlow(C1, D1, p,q, Alpha, nf, np,nt, dia,  patchSize); 
            end   
             % Lin 4/1/2024 ----- from NwkSimHeatmap
             function [pp2, ff2, ppAv2, mbError]= solveBloodFlowWithPP(nwk, C1,C2, BC, alpha);
             [pp2, ff2, ppAv2, mbError]= solveBloodFlowWithPP(nwk, C1,C2, BC, alpha);
             end;  
            function [mbError] = mbError(ff, C1, C2)
                IOFluxes = C2*ff; 
                mbError= sum(IOFluxes) % should be zero 
            end
            % make for delte ---- fails for Neemann BC
            function [mbError] = mbErrorOld(ff, C1, C2, D1)
                IOFluxesRaw2=C2*ff; IOFluxes2 = D1*C2*ff; 
                mbError= sum(IOFluxes2) % should be zero 
            end
            function n = assignDiameters(n);
                 n = assignDiameters(n);
            end;  
            function n = assignDiametersRedistribute(n);
                 n = assignDiametersRedistribute(n);
            end;      
            function n = assignDiametersRedistributeInAT(n);
                  n = assignDiametersRedistributeInAT(n);
            end
            function n = scaleDiameters(n, scale);
%                 n = assignDiametersRedistributeInAT(n); % dont reassign diameters
                  phi=scale*(n.dia.^3); 
                  n.dia=phi.^(1/3);                
            end 
    end   
end

function [C1, alpha, D1, p, q, feedLocations, patchSize]=setUpHeatMapWithFeeds(s, Npatches)
%Npatches=50;
% Lin we must not have any repeats
%feedLocations=sort(randi(s.np, [1 Npatches])); % partition surface and sort
%feedLocations=(randi(s.np, [1 Npatches])); % partition entire surface-no sort
% Lin 4/22/2002
feedLocations=sort(randsample(1:s.np, Npatches));
%Adjust boundary conditions
[D1,p]= makePressureBC(s.BC, s.np, s.nf, s.nt); 
patchSize=0.1*ones(s.np,1); % for debug purposes
p = 0*(1:s.nt)'; % no boundary pressures are assumed in the reactive case
q(s.nf+1:s.nt,1)=0;
q(feedLocations+s.nf)=100; % all feeds have same strength
%Solution%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%nwkSim.test; % do flow computatons in here
alpha = nwkSim.Resistance(s.ptCoordMx, s.faceMx, s.dia, s.nf);% Resistance calculation
C1    = nwkSim.ConnectivityMx(s.nf,s.np,s.faceMx); %no loops matrix of coeff-AL
end

function alpha= Resistance(ptCoordMx, faceMx, dia, nf )%mmHg.Min\ml
    r=ResistanceVector(ptCoordMx, faceMx, dia, nf );
    alpha = sparse(1:nf,1:nf,r,nf,nf); % avoid loop
end

function alpha= Resistance_mm(ptCoordMx, faceMx, dia, nf )%mmHg.Min\ml
    r=ResistanceVector_mm(ptCoordMx, faceMx, dia, nf );
    % avoid loop
    alpha = sparse(1:nf,1:nf,r,nf,nf); % avoid loop
end

function alphainv= ResistanceInv(ptCoordMx, faceMx, dia, nf )
    r=ResistanceVector(ptCoordMx, faceMx, dia, nf );
    alphainv = sparse(1:nf,1:nf,1./r,nf,nf); % avoid loop
end

% alphainv=spdiags(alpha, 0);
% alphainv=sparse(1:nwk.nf, 1:nwk.nf, 1./alphainv, nwk.nf, nwk.nf);

% MJ 12/5/2022
function r= ResistanceVector(ptCoordMx, faceMx, dia, nf )%mmHg.s\ml
    mu=5.3317E-7*60;  %mmHg/s    
    f=128*mu/pi;   
    l= vecnorm((ptCoordMx(faceMx(:,2),:)-ptCoordMx(faceMx(:,3),:)),2,2);
    d4 = dia.^4;
    r = f*(l./d4)*1000;%conversion of mm3 to ml
    % alpha = sparse(nf, nf); for i=1:nf alpha(i,i)=r(i); end;   
% Lin 10/12/2022 --- dont cut this value
    for j =1 : nf 
    if r(j)<0.001
        r(j) = r(1); end;
    end;
    %    alpha = sparse(1:nf,1:nf,r,nf,nf); % avoid loop
end

% MJ/Lin 12/5/2022
function r= ResistanceVector_mm(ptCoordMx, faceMx, dia, nf )%mmHg.s\ml
    mu=5.3317E-7;  %mmHg/min  
    f=128*mu/pi;   
    l= vecnorm((ptCoordMx(faceMx(:,2),:)-ptCoordMx(faceMx(:,3),:)),2,2);
    d4 = dia.^4;
    r = f*(l./d4)*1000;%conversion of mm3 to ml
end

function r= DiameterFreeResistanceVector(ptCoordMx, faceMx, nf )%mmHg.s\ml
    mu=5.3317E-7*60; %mmHg/s     
    f=128*mu/pi;   
    l= vecnorm((ptCoordMx(faceMx(:,2),:)-ptCoordMx(faceMx(:,3),:)),2,2);
    r = f*l.*1000;%conversion of mm3 to ml
end

function C1= ConnectivityMx2(nf,np,faceMx)
    fi = [(1:nf)];
    p1 = faceMx(:,2)'; p2 = faceMx(:,3)'; % P1IDx   % P2 Idx
    C1=sparse([fi, fi], [p1, p2],[ones(1,nf), (-1)*ones(1,nf)],nf,np);
end

function [ff, pp, ppAv] = solveReactiveFlow(C1, D1, p,q, Alpha, nf, np,nt, dia,  patchSize)
% reactive terms
ptArea = patchSize; % default patch area;
Qtot = sum(ptArea);
k=-0.001;%D3 = spdiags(k*ptArea,0,np,np); % avoid loop
D3=sparse(1:np, 1:np,k*ptArea,np,np);
% reactive source terms end-------------
% change signs when dealing with source terms plus is inflow, minus means outflow of node
C2=C1'; E=(speye(np)-D1)*C2;     % C2= C1 transpose
M= [Alpha, -C1; -E, D3];%concatenate matrix
xx=M\(p-q);%Solution
rr=M*xx-p;
ff=xx(1:nf,1);  pp=xx(nf+1:nt,1);ff = ff*1e6;ppAv=0.5*abs(C1(:,:))*pp;
end


% Lin 4/3/2024 ---- blood flow lean --- from nwkSimHEatMap
function [pp2, ff2, ppAv2, mbError]= solveBloodFlowWithPP(nwk, C1,C2, BC, alpha);
%[D1,p2]= makeLeanPressureBC(BC, nwk.np, nwk.nf, nwk.nt);
[D1,p2]= makeLeanPressureBCwithQ(BC, nwk.np, nwk.nf, nwk.nt);
alphainv=spdiags(alpha, 0);
alphainv=sparse(1:nwk.nf, 1:nwk.nf, 1./alphainv, nwk.nf, nwk.nf);
E2=(speye(nwk.np)-D1)*C2;%  C2= C1 transpose 
E2=E2*alphainv*C1;
%%%%%%%%%%%%%%%%% solve for pressures only 
M2= [E2+D1];%concatenate matrix
xx2=M2\p2;%Solution
%  
rr2=M2*xx2-p2; norm(rr2);
pp2=xx2; ppAv2=0.5*abs(C1(:,:))*pp2;ff2=alphainv*C1*pp2;  
[mbError] = nwkSim.mbError(ff2, C1, C2);
end

function [faceMx,ptCoordMx,grpMx, dia,BC,np,nf,nt]=caseReaderAL(filename)
    myfileName = strcat(filename,'.fMx');
    faceMx = load(myfileName);
    myfileName = strcat(filename,'.pMx');
    ptCoordMx = load(myfileName);
    np= length(ptCoordMx);    nf= length(faceMx(:,2));   nt= np+nf;
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

function [D1,p]= makePressureBC(BC, np, nf, nt)
    D1=sparse(np,1); 
    D1(BC(:,1),1)= BC(:,2);  % assign the value of 1 (Dirichlet) or 0 for Neumann 
    D1=sparse(diag(D1));     %D-matrix assignments
    p=zeros(nt,1);
    p_bar=sparse(np,1); p_bar(BC(:,1),1)= BC(:,3);%BC  
    p(nf+1:nt,1)=sparse(D1*p_bar);
end

function n = assignDiameters(n);
C1 = ConnectivityMx2(n.nf,n.np,n.faceMx); % C2=C1' dont use C2; 
[inFlows, outFlows]=nwkHelp.findBoundaryNodes(n);
% Lin 4/12/2022 we need to control flow distrionbution
bcMx1 = [inFlows',1*ones(length(inFlows),1),0*ones(length(inFlows),1)];
bcMx2 = [outFlows',2*ones(length(outFlows),1),1*ones(length(outFlows),1)];
bcMx=[bcMx1;bcMx2];
[D1,p,q]=readFlowBC(bcMx, n.np, n.nf, n.nt); % new version load BC in reader
MF= [2*speye(n.nf), C1; (speye(n.np)-D1)*C1', D1]; %concatenate matrix
xx=MF\(p-q); ff=xx(1:n.nf,1);  lambda=xx(n.nf+1:n.nt,1); % compute flow 
dia=abs(ff)*1*10e-2;
n.dia = dia.^(1/3);
% validate balances
IOFluxes = C1'*ff;
MBdiff =sum(IOFluxes); % MBDiff should be zero
end

% Lin 4/3/2022 try solving for flows and lambda 
function n = assignDiametersRedistribute(n);
C1 = ConnectivityMx2(n.nf,n.np,n.faceMx); % C2=C1' dont use C2; 
[inFlows, outFlows]=nwkHelp.findBoundaryNodes(n);
% Lin 4/12/2022 we need to control flow distribution
%bcMx1 = [inFlows',1*ones(length(inFlows),1),0*ones(length(inFlows),1)];
totalFlux = length(outFlows);
bcMx1=[1 2 -0.45*totalFlux; 962 2 -0.45*totalFlux; 1255 1 0]; % last node is free at 10% of totalFluxes
bcMx2 = [outFlows',2*ones(length(outFlows),1),1*ones(length(outFlows),1)];
bcMx=[bcMx1;bcMx2];
[D1,p,q]=readFlowBC(bcMx, n.np, n.nf, n.nt); % new version load BC in reader
MF= [2*speye(n.nf), C1; (speye(n.np)-D1)*C1', D1]; %concatenate matrix
xx=MF\(p-q); ff=xx(1:n.nf,1);  lambda=xx(n.nf+1:n.nt,1); % compute flow 
dia=abs(ff)*1*10e-2;
n.dia = dia.^(1/3);
% validate balances
IOFluxes = C1'*ff;
MBdiff =sum(IOFluxes); % MBDiff should be zero
end

% Lin 5/9/2022 solve for flow but use generic BC
function n = assignDiametersRedistributeInAT(n);
C1 = ConnectivityMx2(n.nf,n.np,n.faceMx); % C2=C1' dont use C2; 
[inFlows, outFlows]=nwkHelp.findBoundaryNodes(n);
% Lin 4/12/2022 we need to control flow distribution
bcMx1 = [inFlows',1*ones(length(inFlows),1),0*ones(length(inFlows),1)];
totalFlux = length(outFlows);
%bcMx1=[1 2 -0.45*totalFlux; 962 2 -0.45*totalFlux; 1255 1 0]; % last node is free at 10% of totalFluxes
bcMx2 = [outFlows',2*ones(length(outFlows),1),1*ones(length(outFlows),1)];
bcMx=[bcMx1;bcMx2];
[D1,p,q]=readFlowBC(bcMx, n.np, n.nf, n.nt); % new version load BC in reader
MF= [2*speye(n.nf), C1; (speye(n.np)-D1)*C1', D1]; %concatenate matrix
xx=MF\(p-q); ff=xx(1:n.nf,1);  lambda=xx(n.nf+1:n.nt,1); % compute flow 
dia=abs(ff)*1*10e-2;
n.dia = dia.^(1/3);
% validate balances
IOFluxes = C1'*ff;
MBdiff =sum(IOFluxes); % MBDiff should be zero
end

function [D1,p,q]= readFlowBC(BC, np, nf, nt)
   idx = find(BC(:,2)==1); % dirichlet bc;
   pts = BC(idx,1); val = BC(idx,3);
   D1 = sparse(pts, pts, 1, np, np);
   %p_bar  = sparse(pts, ones(length(pts),1), val,np,1);
   p  = sparse(nf+pts, ones(length(pts),1), val,nt,1);% global indexed
   p=full(p); % make full for writeout and display pur[oses;
   % add Neumann for Patrice
   idx = find(BC(:,2)==2); % neumann bc;
   pts = BC(idx,1); val = BC(idx,3); 
   % D values are zero ---- which is the default
   q = sparse(nf+pts, ones(length(pts),1), val,nt,1);%global indexed
   q=full(q);
end


% Lin 4/1/2024 ---- version for p and q 
%%% cipied from nwkSimHEatMap
% assignment needs to be make room for an empty bc
function [D1,p] = makeLeanPressureBCwithQ(BC, np, nf, nt)
    p=zeros(np,1);
    if length(BC) == 0 return; end
    idx = find(BC(:,2)==1); % dirichlet bc;
    pts = BC(idx,1); val = BC(idx,3);
    D1 = sparse(pts, pts, 1, np, np);
    p(pts)=val;
    % now read q values;
    idx = find(BC(:,2)==2); % neumann bc;
    pts = BC(idx,1); val = BC(idx,3); 
    % D values are zero ---- which is the default
    p(pts) = val;
end

    


