classdef JustaAHRSPureFastMr2 < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SamplePeriod = 1/256;
        Quaternion = [1 0 0 0];     % output quaternion describing the Earth relative to the sensor
        Beta = 1;               	% algorithm gain
        
        test=[0 0 0 0];
        test2=[0 0 0 0];
        gain=0.0528152;
        wAcc=0.00248;
        wMag=1.35e-04;
        
        mr_z=0.895;
        
        Imu=1;
    end
    
    methods (Access = public)
        function obj = JustaAHRSPureFastMr2(varargin)
            for i = 1:2:nargin
                if  strcmp(varargin{i}, 'SamplePeriod'), obj.SamplePeriod = varargin{i+1};
                elseif  strcmp(varargin{i}, 'Quaternion'), obj.Quaternion = varargin{i+1};
                elseif  strcmp(varargin{i}, 'Beta'), obj.Beta = varargin{i+1};
                else error('Invalid argument');
                end
            end;
        end
        function obj = Update(obj, Gyroscope, Accelerometer, Magnetometer)
            q = obj.Quaternion; % short name local variable for readability
            
            % Normalise accelerometer measurement
            if(norm(Accelerometer) == 0), return; end	% handle NaN
            acc = Accelerometer / norm(Accelerometer);	% normalise magnitude
            
            % Normalise magnetometer measurement
            if(norm(Magnetometer) == 0), return; end	% handle NaN
            mag = Magnetometer / norm(Magnetometer);	% normalise magnitude
            
            qDot=0.5 *obj.SamplePeriod * quaternProd(q, [0 Gyroscope(1) Gyroscope(2) Gyroscope(3)]);
            qp= q + qDot;
            
            
            %             h = quaternProd(q, quaternProd([0 Magnetometer], quaternConj(q)));
            %             mr = [norm([h(2) h(3)]) 0 h(4)]/norm([norm([h(2) h(3)]) 0 h(4)]);
            
            R=[2*(0.5 - qp(3)^2 - qp(4)^2)   2*(qp(1)*qp(4) + qp(2)*qp(3))   2*(qp(2)*qp(4) - qp(1)*qp(3))
                2*(qp(2)*qp(3) - qp(1)*qp(4))  2*(0.5 - qp(2)^2 - qp(4)^2)  2*(qp(1)*qp(2) + qp(3)*qp(4))
                2*(qp(1)*qp(3) + qp(2)*qp(4))  2*(qp(3)*qp(4) - qp(1)*qp(2))  2*(0.5 - qp(2)^2 - qp(3)^2)];
            
            ar=[0 0 1];
            accMesPred=(R*ar')';
            
%             h=(R'*mag')';
%             mr=[norm([h(1) h(2)]) 0 h(3)];
            
             obj.mr_z= dot(acc,mag);
            mr_x=sqrt(1-obj.mr_z^2);
            mr=[mr_x 0 obj.mr_z];
            magMesPred=(R*mr')';
            
            ca=cross(acc,accMesPred);
            n=norm(ca);
            veca=ca/n;
            phia=(asin(n)*obj.gain);
            if(phia>obj.wAcc)
                if((phia/obj.gain)>0.15)
                    phia=obj.wAcc;
                else
                    phia=obj.wAcc;
                end
            end
            %             phia=obj.wAcc;
            obj.test=[mr 0];
            
            cm=cross(mag,magMesPred);
            n=norm(cm);
            vecm=cm/n;
            phim=(asin(n)*obj.gain);
            if(phim>obj.wMag)
                phim=obj.wMag;
            end
            %             phim=obj.wMag;
            qCor=[1 veca*phia/2+vecm*phim/2];
            
            quat=quaternProd(qp,qCor);
            
            %             quat=quatGyrPred;
            if(quat(1)<0)
                quat=-quat;
            end
            
            obj.Quaternion = quat/norm(quat);
        end
        
        function obj = UpdateIMU(obj, Gyroscope, Accelerometer)
            q = obj.Quaternion; % short name local variable for readability
            
            % Normalise accelerometer measurement
            if(norm(Accelerometer) == 0), return; end	% handle NaN
            acc = Accelerometer / norm(Accelerometer);	% normalise magnitude
            
            qDot=0.5 *obj.SamplePeriod * quaternProd(q, [0 Gyroscope(1) Gyroscope(2) Gyroscope(3)]);
            qp= q + qDot;
            
            ar=[0 0 1];
            
            R=[2*(0.5 - qp(3)^2 - qp(4)^2)   2*(qp(1)*qp(4) + qp(2)*qp(3))   2*(qp(2)*qp(4) - qp(1)*qp(3))
                2*(qp(2)*q(3) - qp(1)*qp(4))  2*(0.5 - qp(2)^2 - qp(4)^2)  2*(qp(1)*qp(2) + qp(3)*qp(4))
                2*(qp(1)*qp(3) + qp(2)*qp(4))  2*(qp(3)*qp(4) - qp(1)*qp(2))  2*(0.5 - qp(2)^2 - qp(3)^2)];
            
            accMesPred=(R*ar')';
            
            ca=cross(acc,accMesPred);
            n=norm(ca);
            veca=ca/n;
            phia=(asin(n)*obj.gain);
            if(phia>obj.wAcc)
                if((phia/obj.gain)>0.15)
                    phia=obj.wAcc;
                else
                    phia=obj.wAcc;
                end
            end
            
            qCor=[1 veca*phia/2];
            
            quat=quaternProdM(qp,qCor);
            
            if(quat(1)<0)
                quat=-quat;
            end
            
            obj.Quaternion = quat/norm(quat);
        end
        
    end
    
end

