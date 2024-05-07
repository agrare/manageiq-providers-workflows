module ManageIQ
  module Providers
    module Workflows
      class BuiltinMethods < BasicObject
        def self.email(params = {}, _secrets = {}, _context = {})
          options = params.slice("To", "From", "Subject", "Cc", "Bcc", "Body", "Attachment").transform_keys { |k| k.downcase.to_sym }

          miq_task = ::GenericMailer.deliver_task(:generic_notification, options)

          {"miq_task_id" => miq_task.id}
        end

        private_class_method def self.email_status!(runner_context)
          miq_task_status!(runner_context)
        end

        private_class_method def self.miq_task_status!(runner_context)
          miq_task = ::MiqTask.find(runner_context["miq_task_id"])
          return error_payload(:cause => "Unable to find MiqTask id: [#{runner_context["miq_task_id"]}]") if miq_task.nil?

          runner_context["running"] = miq_task.state != ::MiqTask::STATE_FINISHED

          unless runner_context["running"]
            runner_context["success"] = miq_task.status == ::MiqTask::STATUS_OK
            runner_context["output"]  = runner_context["success"] ? miq_task.message : {"Error" => "States.TaskFailed", "Cause" => miq_task.message}
          end

          runner_context
        end

        private_class_method def self.error_payload(cause:, error: "States.TaskFailed")
          {"running" => false, "success" => false, "output" => {"Error" => error, "Cause" => cause}}
        end
      end
    end
  end
end
