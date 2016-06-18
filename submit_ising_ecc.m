function result = submit_ising_ecc(h_logical,J_logical,param,translateFnHandle)
%SUBMITINSTANCE submits an physical Ising instance to DWave and returns the result.
%USAGE:
%   result = submit_ising_ecc(h_physical,J_physical,param,translateFnHandle,beta)
%
%INPUT:
%   h_logical  : The physical local fields.
%   J_logical  : The physical couplings.
%       Couplings will be scaled down to [-1,1] range if necessary. No scale up would be done.
%   param      : parameters to be send to D-Wave
%   tranlateFnHandle : A handle to function that can convert logical to physical Ham.
%   beta       : The required penalty couplings.
%OUTPUT:
%   result     : The raw result from D-Wave

%These parameters never change.
param.auto_scale  = false;
param.answer_mode = 'raw';

%Manually scale the couplings and local fields of logical Hamiltonian.
J_max = max(abs(J_logical(:))); h_max = max(abs(h_logical(:)));
scaleFactor = max([J_max h_max 1]);
h_logical = h_logical/scaleFactor; J_logical = J_logical/scaleFactor;


%Convert to physical Hamiltonian with external energy scale and penalty couplings.
[h_physical,J_physical] = translateFnHandle(h_logical,J_logical,beta);

%And submit the physical problem and return the result.
result = dwGraph.submit_ising(h_physical,J_physical,param);

end
