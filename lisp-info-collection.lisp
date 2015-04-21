(ql:quickload :drakma)
(ql:quickload :yason)
(ql:quickload :alexandria)
(ql:quickload :cxml)

;デフォルトのエンコードを指定
(setf drakma:*drakma-default-external-format* :utf-8)

; ボディを文字列で取得するために、テキストとして判定される Content-Type を追加
(pushnew '("application" . "json") drakma:*text-content-types* :test #'equal)
(multiple-value-bind (body status)
    (drakma:http-request "https://qiita.com/api/v1/tags/common-lisp/items")
  (when (= status 200)
    (defvar *qiita-json-array* body)))

;連想配列の形をした文字列をhashtabeのベクターのs式に
(let* ((yason:*parse-json-arrays-as-vectors* t)
       (qiita-article-array (yason:parse *qiita-json-array*)))
  (defparameter *qiita-article-array* qiita-article-array))

(defparameter *article-bucket* (make-array 5 :fill-pointer 0 :adjustable t))

;qiita-article-arrayから必要な情報を抽出
(loop for article across *qiita-article-array* do
  (let* ((id (gethash "id" article))
        (updated_at (gethash "updated_at" article))
        (url (gethash "url" article))
        (title (gethash "title" article))
        (user (gethash "user" article))
        (user_name (gethash "url_name" user))
         (universal_updated_at (encode-universal-time (parse-integer (subseq updated_at 17 19)) (parse-integer (subseq updated_at 14 16)) (parse-integer (subseq updated_at 11 13)) (parse-integer (subseq updated_at 8 10)) (parse-integer (subseq updated_at 5 7)) (parse-integer (subseq updated_at 0 4)) 9)))
      (vector-push-extend (alexandria:plist-hash-table '( "article-id" id "updated_at" universal_updated_at "url" url "title" title "user_name" user_name) :test #'equal) *article-bucket*)
      (print (alexandria:plist-hash-table '( "article-id" id "updated_at" universal_updated_at "url" url "title" title "user_name" user_name) :test #'equal)))))
   ; (format t "article-id:  ~A~%user: ~A~%title: ~A~%update_at: ~A~%url: ~A~%~%~%" id user_name title universal_updated_at url))))


(let ((a 1) (b 2) (c 3))
  (print a))



(print (gethash "title" *article-bucket*))

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
       
