function [slotOpen,waitTime] = isTimeSlot()
%Returns true and 0 if time slot on D-wave is open, else returns false and
%time to wait (in sec) before D-wave will open

currentTime = clock;
currentTime(1:3) = 1; %Set date to 01/01/0001 1st Jan 0001.
currentTime = datetime(currentTime);

%A date-time vector is a six float column vector with entries
%[year month date hh mm ss]
totalSlots = 6;
slotStartTime = ones(totalSlots,6); 
slotEndTime   = ones(totalSlots,6);

slotStartTime(1,4:6) = [3 0 0];    	% 03:00 AM
slotStartTime(2,4:6) = [8 30 00];  	% 08:30 AM
slotStartTime(3,4:6) = [13 15 00]; 	% 01:15 PM
slotStartTime(4,4:6) = [18 00 00]; 	% 06:00 PM
slotStartTime(5,4:6) = [22 15 00]; 	% 10:15 PM
slotStartTime(6,4:6) = [00 00 00]; 	% 00:00 AM
                                           
slotEndTime(1,4:6) = [5 0 0];           % 05:00 AM
slotEndTime(2,4:6) = [10 30 00];        % 10:30 AM
slotEndTime(3,4:6) = [15 15 00];        % 03:15 PM
slotEndTime(4,4:6) = [19 00 00];        % 07:00 PM
slotEndTime(5,4:6) = [23 59 59];        % 11:59:59 PM
slotEndTime(6,4:6) = [00 15 00];        % 00:15 AM

slotStartTime = datetime(slotStartTime);
slotEndTime   = datetime(slotEndTime);

slotOpen = false;

%Check if the current time is in any one of the slots.
for ii=1:totalSlots
    if isbetween(currentTime,slotStartTime(ii),slotEndTime(ii))
        slotOpen = true;
        break;
    end
end

if ~slotOpen
   timeDiff = slotStartTime - currentTime;
   waitTime = min(timeDiff(timeDiff>0)); %Find the minimum positive difference.
   waitTime = seconds(waitTime);
else
    waitTime = 0;
end
