function draw_state(outfile,flips,J,s,region)

preamble = ['\\documentclass[landscape]{article}\n\n'...
    '\\usepackage[margin=1in]{geometry}\n'...
    '\\usepackage{amsmath}\n'...
    '\\usepackage[usenames,dvipsnames]{xcolor}\n'...
    '\\usepackage{tikz}\n\n'...
    '\\pgfdeclarelayer{edgelayer}\n'...
    '\\pgfdeclarelayer{nodelayer}\n'...
    '\\pgfsetlayers{edgelayer,nodelayer,main}\n\n'...
    '\\tikzstyle{color0f}=[circle,fill=YellowGreen,minimum size=9mm]\n'...
    '\\tikzstyle{color1f}=[circle,fill=SkyBlue,minimum size=9mm]\n'...
    '\\tikzstyle{color2f}=[circle,fill=Goldenrod,minimum size=9mm]\n'...
    '\\tikzstyle{color3f}=[circle,fill=BurntOrange,minimum size=9mm]\n'...
    '\\tikzstyle{color4f}=[circle,fill=BrickRed,minimum size=9mm]\n'...
    '\\tikzstyle{color1c}=[line width=0.75mm, Salmon]\n'...
    '\\tikzstyle{color2c}=[line width=0.75mm, Orchid]\n'...
    '\\tikzstyle{color3c}=[line width=0.75mm, Purple]\n'...
    '\\tikzstyle{color4c}=[line width=0.75mm, Periwinkle]\n'...
    '\\tikzstyle{color5c}=[line width=0.75mm, Violet]\n'...
    '\\tikzstyle{color6c}=[line width=0.75mm, BlueViolet]\n\n'...
    '\\begin{document}\n\n'...
    '\\begin{tikzpicture}[scale=0.7, every node/.style={transform shape}]\n'...
    '\\begin{pgfonlayer}{nodelayer}\n\n'];
    


%choose some colors for qubits with 0, 1, 2, 3, and 4 bit flips
node_colors = ['color0f';'color1f';'color2f';'color3f';'color4f'];
line_colors = ['color1c';'color2c';'color3c';'color4c';'color5c';'color6c'];

fid = fopen(outfile,'w');
fprintf(fid,preamble);

%now we have to write the qubit grid
for q = region
    %determine the x and y coordinates of the node from the qubit
    %number
    if(mod(q,2) == 0) %even numbered qubit
        x_base = mod(q,16)/2;
        x = (x_base-1)*4;
    else
        x_base = (mod(q,16)-1)/2;
        x = (x_base-1)*4+2;
    end

    y_base = floor(q/16);
    if(mod(q,2) == 0) %even numbered qubit
        y = 16 - 2*y_base+1;
    else
        y = 16 - 2*y_base;
    end

    fprintf(fid,'\\node [style=%s] (%g) at (%g, %g) {%g};\n',node_colors((flips(q+1,s)+1),:),q,x,y,q);
end

fprintf(fid,'\n\n\\end{pgfonlayer}\n\\begin{pgfonlayer}{edgelayer}\n\n');

for q1 = region
    for q2 = region
        coupling = J(q1+1,q2+1) + J(q2+1,q1+1);
        c_index = coupling*6;
        if(coupling~=0)
            fprintf(fid,'\\draw [style=%s] (%g) to (%g);\n',line_colors(c_index,:),q1,q2);
        end
    end
end

fprintf(fid,'\n\n\\end{pgfonlayer}\n\\end{tikzpicture}\n\\end{document}\n');

fclose(fid);