function [result,gauges] = submit_ising_ecc_gauges(h_logical,J_logical,param,translateFnHandle,penalty)
%SUBMIT_ISING_ECC_GAUGES submits an logical Ising instance to DWave and returns the result
%                        in physical qubits..
%USAGE:
%   result = submit_ising_ecc_gauges(h_logical,J_logical,param,translateFnHandle,penalty)
%
%INPUT:
%   h_logical  : The logical local fields.
%   J_logical  : The logical couplings.
%       Couplings will be scaled down to [-1,1] range if necessary. No scale up would be done.
%   param      : parameters to be send to D-Wave
%   tranlateFnHandle : A handle to function that can convert logical to physical Ham.
%   penalty    : The required penalty couplings.
%OUTPUT:
%   result     : The raw result from D-Wave
%   gauges     : The gauges used in problem submission. The raw results must be transformed
%                to get answers in original gauge.

%These parameters never change.
param.auto_scale  = false;
param.answer_mode = 'raw';

%Manually scale the couplings and local fields of logical Hamiltonian.
J_max = max(abs(J_logical(:))); h_max = max(abs(h_logical(:)));
scaleFactor = max([J_max h_max 1]);
h_logical = h_logical/scaleFactor; J_logical = J_logical/scaleFactor;

%Convert to physical Hamiltonian with external energy scale and penalty couplings.
[h_physical,J_physical] = translateFnHandle(h_logical,J_logical,penalty);

%And submit the physical problem and return the result.
[result,gauges] = dwGraph.submit_ising_gauges(h_physical,J_physical,param);

end
