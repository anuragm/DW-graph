function linkExist = is_valid_coupling(ii,jj,workingCouplers)
%ISVALIDCOUPLING checks if two qubits are connected on physical graph.
%USAGE linkExist = isValidCoupling(ii,jj,workingCouplers)
% Inputs:
%      ii and jj - the two physical qubits
%      workingCouplers - a matrix of length 2xnumOfCouplings, gotten from DW2 solver properties.

linkExist = (ismember([ii jj],workingCouplers','rows')) || ...
            (ismember([jj ii],workingCouplers','rows'));

end
