function result = submit_ising(h_physical,J_physical,param)
%SUBMITINSTANCE submits an physical Ising instance to DWave and returns the result. 
%USAGE:
%   result = submit_ising(h_physical,J_physical,param)
%
%INPUT:
%   h_physical  : The physical local fields.
%   J_physical  : The physical couplings.
%       Coulings will be scaled down to [-1,1] range if necessary. No scale up would be done.
%   param      : parameters to be send to DW2.
%OUTPUT:
%   result     : The raw result from D-Wave

%These parameters never change.
param.auto_scale  = false;
param.answer_mode = 'raw';

%Manually scale the couplings and local fields of physical hamiltonian.
J_max = max(abs(J_physical(:))); h_max = max(abs(h_physical(:)));
scaleFactor = max([J_max h_max 1]);
h_physical = h_physical/scaleFactor; J_physical = J_physical/scaleFactor;
    
%Open an error file to write errors. This will help in not polluting main
%window.
fileHandle = fopen('errors.txt','at');

persistent solver; persistent shouldRenewSolver ;

while(true)
    try
        if( isempty(solver) || shouldRenewSolver)
            %(Re)Initialise Vesuvious
            load('solverSettings.mat','urlDwave','myToken','solverName');
            while(true)
                try
                    connHandle = sapiRemoteConnection(urlDwave,myToken);
                    solver = sapiSolver(connHandle,solverName);
                    shouldRenewSolver = false;
                    break;
                catch errorE
                    disp(errorE)
                    fprintf(['Fatal error in creating a solver. Are you sure you can connect' ...
                             ' to DW2? \n']);
                    
                    fprintf('Retrying ...\n');
                end
            end
        end
        
        %Just check once before submission if the timeslot is closed.
        [slotOpen,waitTime]=isTimeSlot();
        if(slotOpen == false)
            fprintf('Waiting for D-wave Time slot to open \n');
            pause(waitTime);
        end
        result = sapiSolveIsing(solver,h_physical,J_physical,param);
        break;
    catch errorObject
        fprintf('!*');
        fprintf(fileHandle, '%s : Error identifier \"%s\" \n',datestr(now), ...
                errorObject.identifier);
        fprintf(fileHandle, '%s : Error message \" %s \" \n' ,datestr(now),errorObject.message);
        pause(5);
        if strcmp(errorObject.identifier,'sapi:NetworkError')
            shouldRenewSolver = true;
        end
    end    
end

fclose(fileHandle);

end
