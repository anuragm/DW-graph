function draw_hamiltonian(fileName,h,J)
%DRAW_HAMILTONIAN draws a state/Hamiltonain on Pudenz code graph.
%given the Ising Hamiltonian (h,J), draw the logical Pudenz code graph.

%Header for .tex file.
preamble = ['\\documentclass[landscape]{article}\n\n'...
    '\\usepackage[margin=1in]{geometry}\n'...
    '\\usepackage{amsmath}\n'...
    '\\usepackage[usenames,dvipsnames]{xcolor}\n'...
    '\\usepackage{tikz}\n\n'...
    '\\pgfdeclarelayer{edgelayer}\n'...
    '\\pgfdeclarelayer{nodelayer}\n'...
    '\\pgfsetlayers{edgelayer,nodelayer,main}\n\n'...
    '\\tikzstyle{valid}=[circle,fill=LimeGreen,minimum size=9mm]\n'...
    '\\tikzstyle{noPenalty}=[circle,fill=BurntOrange,minimum size=9mm]\n'...
    '\\tikzstyle{unUsed}=[circle,fill=Gray,minimum size=9mm]\n'...
    '\\tikzstyle{invalid}=[circle,fill=Red,minimum size=9mm]\n'...
    '\\tikzstyle{joinedLine}=[line width=0.75mm, BlueViolet]\n'...
    '\\tikzstyle{dottedLine}=[line width=0.75mm, dotted, BlueViolet]\n\n'...
    '\\begin{document}\n\n'...
    '\\pagenumbering{gobble}\n\n'...
    '\\begin{tikzpicture}[scale=0.35, every node/.style={transform shape},y=-1cm]\n'...
    '\\begin{pgfonlayer}{nodelayer}\n\n'];

fid = fopen([fileName '.tex'],'w');
fprintf(fid,preamble);

%Load required maps.
%And now save all these structures.
currentFilePath = mfilename('fullpath');
parentDir = fileparts(currentFilePath);
codeFile = fullfile(parentDir,'code.mat');
holeFile = fullfile(parentDir,'holes.mat');
load(holeFile,'holes');
load(codeFile,'code','logicalNgbr');
totalQubits = length(logicalNgbr); 
numOfCells = sqrt(totalQubits/2);
%keyboard;

%The even nodes are arranged in every other line, and so are the odd nodes. 
for qubit = 0:(totalQubits-1)

    xpos = 2*mod(qubit,2*numOfCells);
    ypos = 2*(2*floor(qubit/(2*numOfCells)) + (mod(qubit,2)~=0));
   
    qubitStyle = 'valid';
    %invalid qubits. 
    if ismember(qubit,holes)
        qubitStyle = 'invalid';
    end
    
    %If the qubit has only three physical qubits, we paint it orange.
    if length(code(qubit))==3
        qubitStyle='noPenalty';
    end
   
    fprintf(fid,'\\node [style=%s] (%g) at (%g, %g) {%g};\n',qubitStyle,qubit,xpos,ypos, ...
                qubit);        
    
end

%Draw the connections from J matrix.
[activeRows, activeColumns] = find(J~=0);
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

%Put in the closing statement.
fprintf(fid,'\n\n\\end{pgfonlayer}\n\\end{tikzpicture}\n\\end{document}\n');
fclose(fid);

%% Now compile to pdf file.
setenv('PATH', [getenv('PATH') ':/usr/local/bin:/usr/texbin/']);
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
