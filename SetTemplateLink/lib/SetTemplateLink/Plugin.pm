package SetTemplateLink::Plugin;

use strict;

sub can_use_set {
    my $app = MT->app;
    return $app->user->is_superuser;
}

sub hdlr_set_linkedfile_templates {
    my $app = shift;
    return $app->permission_denied() unless $app->user->is_superuser;

    my $blog    = $app->blog;
    my $blog_id = $app->blog->id;
    my $plugin  = MT->component('SetTemplateLink');
    my $path =
      $plugin->get_config_value( 'set_template_path', "blog:$blog_id" );

    return $app->error(
        $app->translate(
            "Should be set the linked path in the plugin setting.: [_1]",
            $plugin->errstr
        )
    ) if !$path;

    my $fmgr = $blog->file_mgr;
    unless ( $fmgr->exists($path) ) {
        $fmgr->mkpath($path);
    }

    if ( $fmgr->exists($path) && $fmgr->can_write($path) ) {
        my @temps = MT::Template->load({ blog_id => $blog_id });
				my $index = 1;
				my $q = $app->param;
				foreach my $temp ( @temps ) {
		            my $template_id = $temp->id;
		            my $basename    = $temp->identifier . '.mtml';
		            my $linked_path = File::Spec->catfile( $path, $basename );
		            $temp->linked_file($linked_path);

								my $c = $fmgr->get_data($linked_path);
								$temp->text($c);
								$temp->build_type(1);

		            $temp->save
		              or die $app->error(
		                $plugin->translate(
		                    "Can not save template linked_file.: [_1]",
		                    $temp->errstr
		                )
		              );

								if( $temp->build_type) {
									if ( $temp->type eq 'index' ) {
										$q->param( 'type', 'index-' . $temp->id );
										$q->param( 'tmpl_id', $temp->id );
										$q->param( 'single_template', 1 );
										require MT::CMS::Blog;
										MT::CMS::Blog::rebuild_pages($app);
									}
									elsif ( $temp->type eq 'archive'
												||	$temp->type eq 'category'
												||	$temp->type eq 'page'
												||	$temp->type eq 'individual' )
									{
										my $static_maps = delete $app->{static_dynamic_maps};
										require MT::TemplateMap;
										my $terms = { blog_id => $blog_id };

										if ( %$terms ) {
											my @maps = MT::TemplateMap->load($terms);
											my @ats = map { $_->archive_type } @maps;
											if ( $#ats >= 0 ) {
												$q->param( 'type', join(',', @ats) );
												$q->param( 'with_indexes', 1 );
												$q->param( 'no_static', 1 );
												$q->param( 'template_id', $temp->id );
												$q->param( 'single_template', 1 );
												require MT::CMS::Blog;
												MT::CMS::Blog::start_rebuild_pages($app);
											}
										};
									}
								};
								$index++;
		    }
		$app->call_return;
    }
    else {
        return $app->error(
            $app->translate(
                "Unable to create file in this path: [_1]", $path
            )
        );
    }

}

1;
