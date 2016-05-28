function draw_hamiltonian(fileName, h, J)
%DRAW_HAMILTONIAN draws a Hamiltonain on Chimera graph.
%given matrix (h,J) for Ising Hamiltonain, draws the Chimera graph demonstrating the
%Hamiltonian. The output is a latex file called fileName.tex, and that is compiled to get
%fileName.pdf. Presumes that latexpdf is installed on system.

%Put in the header for tex file.
preamble = ['\\documentclass{article}\n\n'...
    '\\usepackage[margin=0.1in]{geometry}\n'...
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
    '\\tikzstyle{dottedLine}=[line width=0.75mm, dotted, BlueViolet]\n'...
    '\\tikzstyle{thick}=[line width = 0.1mm]\n\n' ...
    '\\begin{document}\n\n'...
    '\\pagenumbering{gobble}\n\n'...
    '\\begin{tikzpicture}[scale=0.25, every node/.style={transform shape},y=-1cm]\n'...
    '\\begin{pgfonlayer}{nodelayer}\n\n'];

fid = fopen([fileName '.tex'],'w');
fprintf(fid,preamble);

%Load the required map.
currentFilePath = mfilename('fullpath');
parentDir = fileparts(currentFilePath);
codeFile = fullfile(parentDir,'code.mat');
holeFile = fullfile(parentDir,'holes.mat');
load(holeFile,'holes');
load(codeFile,'logicalNgbr');

totalQubits = length(logicalNgbr);
workingQubits = setdiff(0:1:(totalQubits-1),holes);
cellSize = sqrt(totalQubits/8);

%First we draw all the working qubits
qubitStyle = 'upSpin';
for ii=workingQubits
    unitCellLoc = floor(ii/8);           %Get the unit cell number.
    unitCellX = mod(unitCellLoc,cellSize);      %Unit cells locations in x-axis
    unitCellY = floor(unitCellLoc/cellSize);    %Unit cell location on y-axis
    
    xpos = 5*unitCellX + ...              %Location of the cell.  
           2*floor((ii-8*unitCellLoc)/4); %Location inside cell.

    ypos = 9*unitCellY + ...               %Location of the cell. 
           2*mod((ii-8*unitCellLoc),4);    %Location inside cell.

    fprintf(fid,'\\node [style=%s] (%g) at (%g, %g) {%g};\n',qubitStyle,ii,xpos,ypos, ...
            ii);
end

%Then we draw all the invalid qubits.
qubitStyle = 'invalid';
for ii=setdiff(0:1:(totalQubits-1),workingQubits')
    unitCellLoc = floor(ii/8);            %Get the unit cell number.
    unitCellX = mod(unitCellLoc,cellSize);       %Unit cells locations in x-axis
    unitCellY = floor(unitCellLoc/cellSize);     %Unit cell location on y-axis
    
    xpos = 5*unitCellX + ...              %Location of the cell.  
           2*floor((ii-8*unitCellLoc)/4); %Location inside cell.

    ypos = 9*unitCellY + ...              %Location of the cell. 
           2*mod((ii-8*unitCellLoc),4);   %Location inside cell.

    fprintf(fid,'\\node [style=%s] (%g) at (%g, %g) {%g};\n',qubitStyle,ii,xpos,ypos, ...
            ii);
end

%Box each unit cell in border
for ii=0:1:((totalQubits-1)/8)
    ypos = 9*floor(ii/cellSize)+3; 
    xpos = 5*mod(ii,cellSize)+1;
    fprintf(fid,['\\node [rounded corners=8pt,draw,minimum height=75mm,minimum width=37mm] '...
                 'at (%d,%d) {};\n'],xpos,ypos);
end

%End the node layer, and start the edge layer.
fprintf(fid,'\\end{pgfonlayer}\n\n');
fprintf(fid,'\\begin{pgfonlayer}{edgelayer}\n');

%Draw each connection.
[activeRows, activeColumns] = find(J~=0);
workingCouplers = zeros(2,length(activeRows));
workingCouplers(1,:) = activeRows-1; workingCouplers(2,:)=activeColumns-1;
for ii=1:size(workingCouplers,2)
    qubit1 = workingCouplers(1,ii); unitCell1 = floor(qubit1/8);
    qubit2 = workingCouplers(2,ii); unitCell2 = floor(qubit2/8); 

    if (unitCell1==unitCell2)    %If they are in same unit cell
        fprintf(fid,'\\draw [style=thick] (%d) to (%d);\n',qubit1,qubit2);
    elseif (unitCell2-unitCell1)==1 %If the qubits are horizontal neighbors.
        fprintf(fid,'\\draw [style=thick, looseness=.7] (%d) to (%d);\n',qubit1,qubit2);
    elseif (unitCell2-unitCell1)==cellSize %If the qubits are vertical neighbors.
        fprintf(fid,'\\draw [style=thick, looseness=.7, bend left = 315] (%d) to (%d);\n', ...
                qubit1,qubit2);
    end
end

%Put in the closing statement.
fprintf(fid,'\n\n\\end{pgfonlayer}\n\\end{tikzpicture}\n\\end{document}\n');
fclose(fid);

%% Now compile to pdf file.
setenv('PATH', [getenv('PATH') ':/usr/local/bin:/usr/texbin']);
command    = sprintf('pdflatex %s.tex',fileName);
[~,~]      = system(command);
command    = sprintf('latexmk -c %s.tex',fileName);
[~,~]      = system(command);
command    = sprintf('pdfcrop %s.pdf',fileName);
[status,~] = system(command);

if ( status ~= 0)
    fprintf('cannot compile latex!\n')
end

end 
