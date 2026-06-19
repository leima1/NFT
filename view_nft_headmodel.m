function view_nft_headmodel(meshname)
%% iew_nft_headmodel.m
%
%   3D viewer for an NFT warped BEM head model. Renders the tissue
%   boundaries (scalp/skull/CSF/brain) as nested transparent surfaces with the
%   electrodes overlaid, and turns on rotate3d so you can spin it.
%
%   Usage:
%     view_nft_headmodel                      % prompts for a .bei file
%     view_nft_headmodel('E:\...\testHC01')   % mesh name (no extension)
%
%   Mesh files (.bec/.bee/.bei) + optional *.sensors are produced by
%   nft_warping_meshLM.
%
% LM 2026
%%
config_local
if exist('bem_load_mesh','file') ~= 2
    addpath('E:\clab\NFT');
end

% locate the mesh
if nargin < 1 || isempty(meshname)
    [fn,fp] = uigetfile('*.bei','Select an NFT mesh info file (.bei)');
    if isequal(fn,0), return; end
    meshname = fullfile(fp, fn(1:end-4));      % strip .bei
end

% accept a folder, a *.bei path, or the bare name prefix
if isfolder(meshname)
    b = dir(fullfile(meshname,'*.bei'));
    if isempty(b), error('No .bei mesh found in folder:\n  %s', meshname); end
    meshname = fullfile(meshname, b(1).name(1:end-4));
elseif endsWith(lower(meshname),'.bei')
    meshname = meshname(1:end-4);
end
if exist([meshname '.bei'],'file') ~= 2
    error('Mesh not found: %s.bei\n(Pass the subject folder, e.g. ...\\nft_headmodels\\sub-HC01)', meshname);
end
mesh = bem_load_mesh(meshname);

% split elements by boundary (outer -> inner)
counts = mesh.bnd(:,1);
stop   = cumsum(counts);
start  = [1; stop(1:end-1)+1];
cols   = [.95 .85 .75; .85 .85 .80; .55 .80 1.0; 1.0 .55 .55];   % scalp skull CSF brain
alph   = [.12 .22 .38 1.0];
names  = {'scalp','skull','CSF','brain'};

% optional electrodes (first *.sensors next to the mesh)
sdir = dir([fileparts(meshname) filesep '*.sensors']);
P = [];
if ~isempty(sdir)
    S = load(fullfile(sdir(1).folder, sdir(1).name), '-mat');
    if isfield(S,'pnt'), P = S.pnt; end
end

% render
figure('Color','w','Name',['NFT head model: ' mesh.name],'NumberTitle','off');
hold on;

if mesh.num_node_elem >= 6
    ncol = [1 3 5]; 
else
    ncol = 1:3; 
end

leg = {};
for b = 1:mesh.num_boundaries
    E   = mesh.elem(start(b):stop(b), :);
    ci  = min(b, size(cols,1));
    patch('Faces', E(:,ncol), 'Vertices', mesh.coord, ...
        'FaceColor', cols(ci,:), 'EdgeColor','none', 'FaceAlpha', alph(ci));
    if b <= numel(names)
        leg{end+1} = names{b};
    end
end
if ~isempty(P)
    plot3(P(:,1),P(:,2),P(:,3),'k.','MarkerSize',12);
    leg{end+1} = 'electrodes';
end

axis equal vis3d off; view(135,20);
camlight headlight; lighting gouraud; material dull;
title([mesh.name '   (' strjoin(leg,' / ') ')'], 'Interpreter','none');
rotate3d on;

end
