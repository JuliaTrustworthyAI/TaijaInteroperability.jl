using TaijaInteroperability

model_file = "neural_network_class"
class_name = "NeuralNetwork"
model_location = "$(pwd())"
model_path = "$(pwd())/neural_network_class.py"
pickle_path = "$(pwd())/pretrained_model.pt"

# Using PyTorch models is supported only for Julia versions >= 1.8
if VERSION >= v"1.8"
    ENV["KMP_DUPLICATE_LIB_OK"] = "TRUE"

    torch = PythonCall.pyimport("torch")
    @testset "PyTorch model test" begin
        for (key, value) in synthetic
            name = string(key)
            @testset "$name" begin
                data = value[:data]
                X = data.X

                # Create and save model in the model_path directory
                create_new_pytorch_model(data, model_path)
                train_and_save_pytorch_model(data, model_location, pickle_path)
                model_loaded = TaijaInteroperability.pytorch_model_loader(
                    model_location,
                    model_file,
                    class_name,
                    pickle_path,
                )

                model_pytorch = TaijaInteroperability.PyTorchModel(model_loaded, data.likelihood)

                @testset "Test for errors" begin
                    @test_throws ArgumentError TaijaInteroperability.PyTorchModel(model_loaded, :regression)
                end

                @testset "$name" begin
                    @testset "Verify the correctness of the likelihood field" begin
                        @test model_pytorch.likelihood == data.likelihood
                    end
                    @testset "Matrix of inputs" begin
                        @test size(Models.logits(model_pytorch, X))[2] == size(X, 2)
                        @test size(Models.probs(model_pytorch, X))[2] == size(X, 2)
                    end
                    @testset "Vector of inputs" begin
                        @test size(Models.logits(model_pytorch, X[:, 1]), 2) == 1
                        @test size(Models.probs(model_pytorch, X[:, 1]), 2) == 1
                    end
                end

                # Clean up the temporary files
                remove_file(model_path)
                remove_file(pickle_path)
            end
        end
    end

    @testset "Counterfactuals for PyTorch models" begin
        # Test the Python models on only one generator to avoid the pipeline getting too slow
        # All generators are tested in the generators/counterfactuals.jl file
        generator = GravitationalGenerator()
        for (key, value) in synthetic
            name = string(key)
            @testset "$name" begin
                counterfactual_data = value[:data]
                X = counterfactual_data.X

                # Create and save model in the model_path directory
                create_new_pytorch_model(counterfactual_data, model_path)
                train_and_save_pytorch_model(
                    counterfactual_data,
                    model_location,
                    pickle_path,
                )
                model_loaded = TaijaInteroperability.pytorch_model_loader(
                    model_location,
                    model_file,
                    class_name,
                    pickle_path,
                )
                M = TaijaInteroperability.PyTorchModel(model_loaded, counterfactual_data.likelihood)

                # Randomly selected factual:
                Random.seed!(123)
                x = DataPreprocessing.select_factual(
                    counterfactual_data,
                    Random.rand(1:size(X, 2)),
                )
                # Choose target:
                y = Models.predict_label(M, counterfactual_data, x)
                target = get_target(counterfactual_data, y[1])
                # Single sample:
                counterfactual = CounterfactualExplanations.generate_counterfactual(
                    x,
                    target,
                    counterfactual_data,
                    M,
                    generator,
                )

                @testset "Predetermined outputs" begin
                    if generator.latent_space
                        @test counterfactual.params[:latent_space]
                    end
                    @test counterfactual.target == target
                    @test counterfactual.x == x &&
                          CounterfactualExplanations.factual(counterfactual) == x
                    @test CounterfactualExplanations.factual_label(counterfactual) == y
                    @test CounterfactualExplanations.factual_probability(counterfactual) ==
                          probs(M, x)
                end

                @testset "Convergence" begin
                    @testset "Non-trivial case" begin
                        counterfactual_data.generative_model = nothing
                        # Threshold reached if converged:
                        γ = 0.9
                        max_iter = 1000
                        conv =
                            CounterfactualExplanations.Convergence.DecisionThresholdConvergence(
                                decision_threshold = γ,
                                max_iter = max_iter,
                            )
                        counterfactual = CounterfactualExplanations.generate_counterfactual(
                            x,
                            target,
                            counterfactual_data,
                            M,
                            generator;
                            convergence = conv,
                        )
                        using CounterfactualExplanations: counterfactual_probability
                        @test !CounterfactualExplanations.converged(conv, counterfactual) ||
                              CounterfactualExplanations.target_probs(counterfactual)[1] >=
                              γ # either not converged or threshold reached
                        @test !CounterfactualExplanations.converged(conv, counterfactual) ||
                              length(path(counterfactual)) <= max_iter
                    end

                    @testset "Trivial case (already in target class)" begin
                        counterfactual_data.generative_model = nothing
                        # Already in target and exceeding threshold probability:
                        y = Models.predict_label(M, counterfactual_data, x)
                        target = y[1]
                        γ = minimum([1 / length(counterfactual_data.y_levels), 0.5])
                        conv =
                            CounterfactualExplanations.Convergence.DecisionThresholdConvergence(
                                decision_threshold = γ,
                            )
                        counterfactual = CounterfactualExplanations.generate_counterfactual(
                            x,
                            target,
                            counterfactual_data,
                            M,
                            generator;
                            convergence = conv,
                            initialization = :identity,
                        )
                        x′ = CounterfactualExplanations.decode_state(counterfactual)
                        if counterfactual.generator.latent_space == false
                            @test isapprox(counterfactual.x, x′; atol = 1e-6)
                            @test CounterfactualExplanations.converged(conv, counterfactual)
                            @test CounterfactualExplanations.terminated(counterfactual)
                        end
                        @test CounterfactualExplanations.total_steps(counterfactual) == 0
                    end
                end

                # Clean up the temporary files
                remove_file(model_path)
                remove_file(pickle_path)
            end
        end
    end
end
