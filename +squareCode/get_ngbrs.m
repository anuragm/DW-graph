function neighbours = get_ngbrs(qubit)
%GET_NGBRS Returns the neighbors of requested qubit.
% Usage:
%    neighbours = get_ngbrs(qubit)
% Inputs:
%    qubit: The qubit whose neighbours are required.
% Outputs:
%    neighbours : An array of all the neighbours of qubit. Invalid qubits have no neighbours.    
    
%Load the dictionary once.
persistent ngbrDict;
if isempty(ngbrDict)
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    dataLoaded = load(fullfile(parentDir,'code.mat'));
    ngbrDict = dataLoaded.logicalNgbr;
end

neighbours = ngbrDict(qubit);
end
