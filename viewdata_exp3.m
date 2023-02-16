%% Experiment 3: View Data
%
% This is MATLAB code that will take in the completed results from a
% drawing experiment, and save the relevant data into a MATLAB structure.
% It will also save the image file of the drawing!
%
% New for Experiment 2:
% This will also save a video of the mouse movements as a MP4 video.
%
% New for Experiment 3:
% This does the same thing as Experiment 2 (saving the image, data, and
% video), but for multiple drawings
%
% Wilma Bainbridge
% March 8, 2021

clear all
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These would be the parts you need to update.

datafile = 'example3-data.csv'; % put in the file path to where your data is.
savepath = 'savedata/'; % put here the file path to where to save the data
savebase = ['data_' date '.mat']; % the save path for the data structure.
imagebase = 'drawing'; % put here the base of the drawing to be saved.
videobase = 'drawingvideo'; % put here the base of the drawing video to be saved.
% Right now it will save them as a JPG and MP4 with the subject number and
% drawing number as a postfix.
% You can update later code to change how it is saved.

% Here's information you could update for Experiment 2
pensize = 2; % Pen size for reconstructing drawing
saveanimation = 1; % 0 = don't save the animation; 1 = save the animation. Not saving it saves processing time.
realtime = 0; % 0 = make a quick animation with no pauses; 1 = make an animation using the same timing as the original drawing
showcolor = 1; % 0 = draw the mouse clicks in black (good for seeing erasures); 1 = draw the mouse clicks in the drawing's color
% Note that for real time, it will take much longer to compile!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Same code as Experiment 1
% This imports the Base 64 converter
import('org.apache.commons.codec.binary.Base64');
base64 = Base64();

% Initialize empty structure to save data
alldata = struct;

% Open the data. Note it expects the delimiter to be |.
inputdata = readtable(datafile,'Delimiter','bar');

for r = 1:size(inputdata,1) % Loop through the participants. Note the example data only has 1.
    disp(['Processing Subject #' num2str(r) ]);
    
    % Save the subject data into a structure
    columns = inputdata.Properties.VariableNames;
    for c = 1:length(columns) % go through each of the columns
        column = columns{c};
        if iscell(inputdata.(column)(r)) % save it into the structure
            alldata(r).(column) = inputdata.(column){r};
        else
            alldata(r).(column) = inputdata.(column)(r);
        end
    end
    
    %% New for Experiment 3: Loop through drawing numbers for multiple drawings
    drawingnum = 1; % start with the first drawing
    drawingid = ['drawing' num2str(drawingnum)]; % name of the column
    while sum(ismember(columns, drawingid))
        
        % Convert the drawing from Base64 to an image and save it.
        % Get the drawing data
        imgdata = alldata(r).(drawingid); % EXP 3: This is now a dynamic field name
        comma = strfind(imgdata,','); % find the comma
        imgdata = imgdata(comma+1:end); % delete the part after the comma
        % Now save it
        filename = [savepath imagebase '_S' num2str(r) '_D' num2str(drawingnum) '.jpg'];
        fid = fopen(filename,'w');
        img_bytes = base64.decode(uint8(imgdata));
        fwrite(fid,img_bytes,'int8');
        fclose(fid);
        
        % New for Experiment 2:
        % Save the animation of the drawing
        if saveanimation
            f2 = figure;
            mousemoveid = ['mousemove' num2str(drawingnum)];
            movementdatastring = alldata(r).(mousemoveid); % EXP 3: This is now a dynamic field name
            if ~strcmp(movementdatastring, '') % if there is movement data saved
                movementdata = textscan(movementdatastring, '%f,%f,%f','Delimiter',';'); % Look at each time point
                
                % Create the video file
                vfilename = [savepath videobase '_S' num2str(r) '_' num2str(drawingnum) '.mp4'];
                vwriter = VideoWriter(vfilename, 'MPEG-4');
                open(vwriter);
                
                % load in the drawing
                drawing = imread(filename);
                
                % Determine the boundaries of the video, as defined by the
                % boundaries of the drawing
                width = size(drawing,2);
                height = size(drawing,1);
                
                % Create an empty image
                emptyfig = 255*ones(height,width,3);
                imshow(emptyfig);
                
                % Save the blank image to start
                drawnow;
                currFrame = getframe; %()
                
                writeVideo(vwriter,currFrame);
                
                % It will now iterate through the time stamps and
                % recreate the mouse movements on the drawing. Please
                % note: This will show the animation as it is
                % recreating the drawing - this is necessary to save
                % the video. Please do not close the figure or move it
                % while it is being constructed!
                
                % There will also be some holes in the drawing, because the
                % mouse movements are sampled are a rate that reflects various
                % properties of the user's browser and computer. Do not be alarmed by these holes!
                
                starttime = movementdata{3}(1);
                for time = 1:min([length(movementdata{1}),length(movementdata{2})])
                    
                    % extract the coordinates for that time
                    xcoord = movementdata{1}(time);
                    ycoord = movementdata{2}(time);
                    
                    % if it's a true coordinate (not the "click"
                    % signifier)
                    if xcoord < 9999 && ycoord < 9999
                        
                        % Make sure the coordinates are integers
                        xcoord = round(xcoord);
                        ycoord = round(ycoord);
                        % disp(['(' num2str(xcoord) ', ' num2str(ycoord) ')']); %
                        % Display coordinate if helpful
                        
                        % Make the reproduced drawing use a pen of
                        % specified size
                        xmin = xcoord - pensize;
                        xmax = xcoord + pensize;
                        ymin = ycoord - pensize;
                        ymax = ycoord + pensize;
                        
                        % Make sure adding a pen doesn't make it go
                        % beyond the image boundaries
                        if xmin <= 0; xmin = 1; end
                        if xmax > width; xmax = width; end
                        if ymin <= 0; ymin = 1; end
                        if ymax > height; ymax = height; end
                        
                        % Draw the image for that frame
                        if showcolor == 0 % if the movements should be drawn in black
                            emptyfig(ymin:ymax,xmin:xmax,:) = zeros(ymax-ymin+1,xmax-xmin+1,3);
                        else % otherwise, draw with the image's color
                            emptyfig(ymin:ymax,xmin:xmax,:) = drawing(ymin:ymax,xmin:xmax,:);
                        end
                        
                        if ~mod(time,10) % don't need to draw every millisecond - draw every 10th
                            % draw that frame and save it in the video
                            imshow(uint8(emptyfig),[0,255]);
                            drawnow;
                            currFrame = getframe;
                            writeVideo(vwriter,currFrame);
                        end
                        
                        % If you want it to be in real time, pause at the same times the participant paused
                        if realtime ~= 0
                            % Find the next time that isn't 9999
                            tempmovedata = movementdata{3}(time+1:end);
                            tempmovedata = tempmovedata(tempmovedata~=9999);
                            % now wait that amount of time
                            if ~isempty(tempmovedata)
                                waittime = tempmovedata(1) - movementdata{3}(time);
                                % disp(['(' num2str(xcoord) ', ' num2str(ycoord) ') waiting ' num2str(waittime)]); %
                                waitframes = (waittime / 1000)*30; % convert milliseconds to frames (assuming 30 fps)
                                for w = 1:waitframes % wait that number of frames
                                    drawnow;
                                    currFrame = getframe;
                                    writeVideo(vwriter,currFrame);
                                end
                            end
                        end
                    end
                    
                end
                
                % save the video when it's done!
                close(vwriter);
                close all
                clear f2 currFrame vwriter
            else
                % Print something if there's no movement data saved
                disp('No movement data here!');
            end
            
            % iterate these values to the next drawing
            drawingnum = drawingnum + 1;
            drawingid = ['drawing' num2str(drawingnum)];
        end
    end
end

save([savepath savebase],'alldata'); % Save the data