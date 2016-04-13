function totalQubits = get_total_qubits()
%Returns the total number of qubits on the graph, working or otherwise.
%Usage:
%  totalQubits = get_total_qubits()
%
%Returns the total number of qubits, like 512 or 1152, etc.

persistent numQubits;
if isempty(numQubits)
    %Load code dictionary.
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    codeFile = fullfile(parentDir,'code.mat');
    load(codeFile,'logicalNgbr');
    
    numQubits = length(logicalNgbr);
end

totalQubits = numQubits;
end
