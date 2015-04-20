(ql:quickload :drakma)
(ql:quickload :yason)
(ql:quickload :alexandria)

;デフォルトのエンコードを指定
(setf drakma:*drakma-default-external-format* :utf-8)

;もう一つのAPIに関しても同じことを行う
(pushnew '("application" . "json") drakma:*text-content-types* :test #'equal)

(multiple-value-bind (body status)
    (drakma:http-request "https://api.stackexchange.com/2.2/questions?page=1&pagesize=50&order=desc&sort=activity&tagged=common-lisp&site=stackoverflow")
  (when (= status 200)
    (defparameter *stackoverflow-json-array* body)))

(defparameter *stackoverflow-articles-array* (gethash "items" (yason:parse *stackoverflow-json-array*)))

(loop for article in *stackoverflow-articles-array* do
     (let ((owner (gethash "owner" article))
           (is_answered (gethash "is_answered" article))
           (last_activity_date (gethash "last_activity_date" article))
           (link (gethash "link" article))
           (title (gethash "title" article)))
       (let ((author_name (gethash "display_name" owner)))
         (format t "updated_at: ~A~%title: ~A~%~%author: ~A~%is_answered: ~a~%url: ~A~%" last_activity_date title author_name is_answered link))))
       
