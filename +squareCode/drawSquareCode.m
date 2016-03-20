%This files generates the sqaure encoded graph by use of helper function
%drawHamiltonian.

totalLogicalQubits = 288;

z = ones(1,totalLogicalQubits);
h = ones(1,totalLogicalQubits);
J = zeros(totalLogicalQubits,totalLogicalQubits);

for qubit = 0:(totalLogicalQubits-1)
    neighbours = squareCode.get_ngbrs(qubit);
    for jj=neighbours
        J(qubit+1,jj+1)=-1;
    end
end

showFields=false;
squareCode.draw_hamiltonian('squareCode',h,J,z,showFields);
