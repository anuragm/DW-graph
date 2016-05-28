function holes = get_holes()
%GET_HOLES returns the list of invalid qubits (holes)

%Load the dictionary once.
persistent holesFileData;
if isempty(holesFileData)
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    dataLoaded = load(fullfile(parentDir,'holes.mat'));
    holesFileData = dataLoaded.holes;
end

holes = holesFileData;
end
