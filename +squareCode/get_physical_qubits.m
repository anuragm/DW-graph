function qubits = get_physical_qubits(logicalQubit)
%GET_PHYSICAL_QUBIT returns the physical qubits corresponding to the logical qubit.
% Returns an array of either no qubits (in case the logicalQubit is invalid), or the four
% qubits that form the logical qubit for square code. 
    
%Load the code block
persistent code;
if isempty(code)
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    codeFile = fullfile(parentDir,'code.mat');
    dataLoaded = load(codeFile);
    code = dataLoaded.code;
end

qubits = code(logicalQubit);
end
