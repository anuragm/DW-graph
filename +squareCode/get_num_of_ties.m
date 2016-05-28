function avgNumOfTies = get_num_of_ties(solutions, listOfQubits)
% GET_NUM_OF_TIES returns the average number of ties for square code in given list of qubits.
% Input:
%   solutions    : The 512xnum_reads solution from DW2
%   listOfQubits : The list of logical qubits used on Square code graph.
% Output:
%   avgNumOfTies = avg. number of ties encountered over num_read runs and
%               length(listOfQubits) qubits

numOfTies = 0;

numOfReads = size(solutions,2);

for logicalQubit = listOfQubits

    physicalQubits = dwGraph.squareCode.get_physical_qubits(logicalQubit);
    physicalData   = solutions(physicalQubits+1,:); %+1 for MATLAB indexing.
    majorityDecode = sum(physicalData,1);
    
    numOfTies = numOfTies + sum(majorityDecode==0); %Add the number of ties for this qubit

end

%Now, average out over number of qubits and number of readouts
avgNumOfTies = numOfTies/(length(listOfQubits)*numOfReads);

end
