;;; Directory Local Variables -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

;; Project-wide (nil): eglot reads workspace configuration in the
;; context of the server's first major mode (yaml-ts-mode), so a
;; yaml-mode-only section would never apply.
((nil
  . ((scotte/yaml-eglot . t)
     (eglot-workspace-configuration
      . (:yaml (:schemas (:kubernetes "kubernetes/**/*.yaml")
                :schemaStore (:enable t)
                :customTags ["!env_var"]
                :validate t
                :completion t
                :hover t))))))
