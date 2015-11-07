function results = cross_validate(data, labels, k)
	new_locs = randperm(length(labels));
	for i=1:length(labels)
		new_loc = new_locs(i);
        transformed_data(new_loc, :) = data(i, :);
	end

	prt_size = floor(length(labels)/k);
	for i=0:(k-1)
		test_idx = [1+(prt_size*i) (prt_size*(i+1))];
		results(i+1, :) = {
			vertcat(data(1:test_idx(1)-1, :), data(test_idx(2)+1:length(labels), :)),
			data(test_idx(1) : test_idx(2), :),
			vertcat(labels(1:test_idx(1)-1), labels(test_idx(2)+1:length(labels))),
			labels(test_idx(1) : test_idx(2)),
	    };
	end
end
