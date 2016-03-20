function draw_hamiltonian(fileName, h, J, z, showFields)
%given matrix (h,J) for Ising Hamiltonain, and state 'z' of the system,
%draws the reduced Chimera with square ECC. The output is a latex file
%called fileName.tex, and that is compiled to get fileName.pdf. Presumes
%that latexpdf is installed on system.

%Put in the header for tex file.
preamble = ['\\documentclass[letterpaper]{article}\n\n'...
    '\\usepackage[margin=0.3in]{geometry}\n'...
    '\\usepackage{amsmath}\n'...
    '\\usepackage[usenames,dvipsnames]{xcolor}\n'...
    '\\usepackage{tikz}\n\n'...
    '\\pgfdeclarelayer{edgelayer}\n'...
    '\\pgfdeclarelayer{nodelayer}\n'...
    '\\pgfsetlayers{edgelayer,nodelayer,main}\n\n'...
    '\\tikzstyle{upSpin}=[circle,fill=LimeGreen,minimum size=9mm]\n'...
    '\\tikzstyle{downSpin}=[circle,fill=BurntOrange,minimum size=9mm]\n'...
    '\\tikzstyle{unUsed}=[circle,fill=Gray,minimum size=9mm]\n'...
    '\\tikzstyle{invalid}=[circle,fill=Red,minimum size=9mm]\n'...
    '\\tikzstyle{joinedLine}=[line width=0.75mm, BlueViolet]\n'...
    '\\tikzstyle{dottedLine}=[line width=0.75mm, dotted, BlueViolet]\n\n'...
    '\\begin{document}\n\n'...
    '\\pagenumbering{gobble}\n\n'...
    '\\begin{tikzpicture}[scale=0.5, every node/.style={transform shape},y=-1cm]\n'...
    '\\begin{pgfonlayer}{nodelayer}\n\n'];

fid = fopen([fileName '.tex'],'w');
fprintf(fid,preamble);

%Draw the nodes. The nodes are colored depending on the local h field, and
%whether or not they are valid qubits.

%Load the missing qubits from holes.mat
currentFilePath = mfilename('fullpath');
parentDir = fileparts(currentFilePath);
codeFile = fullfile(parentDir,'code.mat');
holeFile = fullfile(parentDir,'holes.mat');
load(holeFile,'holes');
load(codeFile,'code','logicalNgbr');
totalQubits = length(logicalNgbr); 
numOfCells = sqrt(totalQubits/2);

for qubit = 0:(totalQubits-1)
    switch z(qubit+1)
        case 1
            qubitStyle = 'upSpin';
        case -1
            qubitStyle = 'downSpin';
        case 0
            qubitStyle = 'unUsed';
    end
    
    if mod(qubit,2*numOfCells)<numOfCells  %Top row of qubits
        xpos = mod(qubit,2*numOfCells)*3;
        ypos = floor(qubit/(2*numOfCells))*4;
    else                %Bottom row of qubits, slightly shifted to give 3D effect
        xpos = (mod(qubit,2*numOfCells) - numOfCells)*3 + 1.5;
        ypos = floor(qubit/(2*numOfCells))*4 + 1.5;
    end
    
    if ismember(qubit,holes)
        qubitStyle = 'invalid';
        fprintf(fid,'\\node [style=%s] (%g) at (%g, %g) {%g};\n',qubitStyle,qubit,xpos,ypos, ...
                qubit);
        continue;
    end
    
    if(showFields)
        fprintf(fid,['\\node[circle,fill=green!%d!orange,minimum size=9mm] (%g) at (%g, %g)' ...
                     ' {%g};\n'],floor((h(qubit+1)+1)/2*100),qubit, xpos, ypos, qubit); 
    else %Show state
        fprintf(fid,'\\node [style=%s] (%g) at (%g, %g) {%g};\n',qubitStyle,qubit,xpos,ypos, ...
                qubit);
    end
end

%Draw the connections from J matrix.
[activeRows, activeColumns] = find(J~=0);
if(showFields)
    %Use solid color lines for ferromagnetic links, and colored dotted line
    %for AFM links.
    
else
    %Use solid line for ferromagnetic links, and dotted lines for AFM links
    for ii=1:length(activeRows)
        if J(activeRows(ii),activeColumns(ii))>0
            lineType = 'joinedLine';
        else
            lineType = 'dottedLine';
        end
        fprintf(fid,'\\draw [style=%s] (%d) to (%d);\n',lineType,activeRows(ii)-1, ...
                activeColumns(ii)-1);
    end
end

%Put in the closing statement.
fprintf(fid,'\n\n\\end{pgfonlayer}\n\\end{tikzpicture}\n\\end{document}\n');
fclose(fid);

%% Now compile to pdf file.
% setenv('PATH', [getenv('PATH') ':/usr/local/bin:/usr/local']);
% command = sprintf('pdflatex %s.tex',fileName);
% [~,~] = system(command);
% command = sprintf('latexmk -c %s.tex',fileName);
% [~,~] = system(command);
%command = sprintf('pdfcrop %s.pdf',fileName);
%[status,~] = system(command);
% 
%if ( status ~= 0)
%    fprintf('cannot compile latex!\n')
%end

fprintf('Please compile \n');

end
